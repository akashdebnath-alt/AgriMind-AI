"""Irrigation plan for a farm.

Two methods:
  * FAO-56 soil water balance (used when past + forecast daily weather is available):
    tracks how empty the soil "bucket" is day by day and says when and how much to irrigate.
  * Simple baseline, ETc = Kc x ET0 minus rain (used when that weather data is not available,
    for example when the server is offline).
"""
from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.time_utils import now_local, today_local
from app.database_models import Farm, IrrigationLog
from app.services import water_balance as wb, weather
from app.services.agronomy import daily_requirement, kc_for

HISTORY_DAYS = 21  # how many past days the water balance looks at


def plan_for_farm_db(db: Session, farm: Farm) -> dict:
    """Looks up the weather and the recent irrigation logs, then builds the plan."""
    forecast = weather.forecast_for_farm(farm, db)
    series = weather.series_for_farm(farm, db)
    since = now_local() - timedelta(days=HISTORY_DAYS + 1)
    logs = db.scalars(
        select(IrrigationLog)
        .where(IrrigationLog.farm_id == farm.id, IrrigationLog.status == "completed",
               IrrigationLog.occurred_at >= since)
        .order_by(IrrigationLog.occurred_at)
    ).all()
    return plan_for_farm(farm, forecast, series, list(logs))


def suggest_next(plans: list[dict]) -> dict:
    """The "next irrigation" card on the Water tab, based on the water balance."""
    window = "6:00 AM - 8:00 AM"
    if not any("irrigate_today" in p for p in plans):  # simple baseline plans: keep the old text
        return {"scheduled": False, "label": "Tomorrow morning", "suggested_window": window}
    if any(p.get("irrigate_today") for p in plans):
        return {"scheduled": False, "label": "Today", "suggested_window": window}
    dates = [date.fromisoformat(p["next_irrigation_date"]) for p in plans if p.get("next_irrigation_date")]
    if not dates:
        return {"scheduled": False, "label": "Not needed in the next 7 days"}
    d = min(dates)
    label = "Tomorrow" if d == today_local() + timedelta(days=1) else f"{d.day} {d.strftime('%b')}"
    return {"scheduled": False, "label": label, "suggested_window": window}


def plan_for_farm(farm: Farm, forecast: dict | None, series: list[dict] | None = None,
                  logs: list[IrrigationLog] | None = None, today: date | None = None) -> dict:
    if series:
        return _water_balance_plan(farm, series, logs or [], today or today_local())
    return _baseline_plan(farm, forecast)


def _num(value, default: float) -> float:
    return float(value) if value is not None else default


def _water_balance_plan(farm: Farm, series: list[dict], logs: list[IrrigationLog], today: date) -> dict:
    forecast_days = [d for d in series if d["date"] >= today][:7]
    live = bool(forecast_days) and forecast_days[0].get("et0_mm") is not None
    assumptions = [
        "Soil is assumed full at the start of the calculation window (planting day or 21 days ago).",
        "The crop coefficient is held at the current growth stage's value for the whole window.",
    ]

    cropped_ha = sum(float(c.area_hectares) for c in farm.crops)
    efficiency = wb.irrigation_efficiency(logs[-1].method if logs else None)
    irrigation_net: dict[date, float] = {}
    if cropped_ha > 0 and not logs:
        assumptions.append("No irrigation was logged in the last 21 days, so none is assumed. "
                           "Use 'Mark as irrigated' after each irrigation for more accurate results.")
    if cropped_ha > 0:
        assumptions.append("Irrigation logs are assumed to be spread evenly over all crops of the farm.")
        for log in logs:
            if log.occurred_at is None or not log.amount_liters:
                continue
            applied_mm = float(log.amount_liters) / (cropped_ha * 10_000)
            day = log.occurred_at.date()
            irrigation_net[day] = irrigation_net.get(day, 0.0) + applied_mm * wb.irrigation_efficiency(log.method)

    crops_out, today_l, week_l, demand_l, area_total = [], 0.0, 0.0, 0.0, 0.0
    any_unknown, soil_unknown = False, False
    any_today, next_dates = False, []
    for crop in farm.crops:
        kc, kc_known = kc_for(crop.crop_name, crop.growth_stage)
        size = wb.bucket_size(farm.soil_type, crop.crop_name, crop.growth_stage)
        if not (kc_known and size["crop_known"]):
            any_unknown = True
            assumptions.append(f"No crop data for '{crop.crop_name}': used a generic crop coefficient and root depth.")
        soil_unknown = soil_unknown or not size["soil_known"]
        if wb.crop_root_params(crop.crop_name)[2] and any(k in crop.crop_name.lower() for k in ("rice", "paddy")):
            assumptions.append("Rice is usually grown in standing water, so this soil-moisture method is only a rough guide for it.")

        start = max(crop.planting_date, today - timedelta(days=HISTORY_DAYS))
        history = [
            {"date": d["date"], "et0_mm": _num(d.get("et0_mm"), settings.default_et0_mm),
             "rain_mm": _num(d.get("rain_mm"), 0.0), "irrigation_mm": irrigation_net.get(d["date"], 0.0)}
            for d in series if start <= d["date"] < today
        ]
        days = [
            {"date": d["date"], "et0_mm": _num(d.get("et0_mm"), settings.default_et0_mm),
             "rain_mm": _num(d.get("rain_mm"), 0.0), "irrigation_mm": irrigation_net.get(d["date"], 0.0)}
            for d in forecast_days
        ]
        res = wb.plan_crop(history, days, kc, size["taw_mm"], size["raw_mm"], size["p"], efficiency)

        area_ha = float(crop.area_hectares)
        et0_today = days[0]["et0_mm"] if days else settings.default_et0_mm
        rain_today = days[0]["rain_mm"] if days else 0.0
        liters_today = res["gross_mm"] * area_ha * 10_000
        today_l += liters_today
        week_l += res["weekly_gross_mm"] * area_ha * 10_000
        demand_l += daily_requirement(kc, et0_today, rain_today, area_ha)["liters"]
        area_total += area_ha
        any_today = any_today or res["irrigate_today"]
        nxt = res["next_irrigation_date"]
        if nxt:
            next_dates.append(nxt)
        crops_out.append({
            "crop_id": crop.id, "crop": crop.crop_name, "growth_stage": crop.growth_stage,
            "kc": kc, "area_hectares": round(area_ha, 4),
            "et0_mm": round(et0_today, 2), "etc_mm": round(kc * et0_today, 2), "rain_mm": round(rain_today, 2),
            "net_irrigation_mm": res["net_mm"], "liters_today": round(liters_today),
            "soil_water_pct": res["soil_water_pct"], "depletion_mm": res["depletion_mm"],
            "taw_mm": res["taw_mm"], "raw_mm": res["raw_mm"],
            "irrigate_today": res["irrigate_today"],
            "next_irrigation_date": nxt.isoformat() if nxt else None,
        })

    if soil_unknown:
        assumptions.append("Soil type unknown: assumed an average water-holding capacity.")
    avg_mm = today_l / (area_total * 10_000) if area_total else 0.0
    earliest = min(next_dates) if next_dates else None
    if not farm.crops:
        text, confidence = "Add a crop to this farm to get an irrigation estimate.", "low"
    elif any_today:
        text = (f"Irrigate today: about {round(today_l):,} L in total (~{avg_mm:.1f} mm over the cropped area). "
                "Irrigate early morning (6-8 AM) to reduce evaporation losses, and check soil moisture before applying.")
    elif earliest:
        text = (f"The soil still holds enough water, so no irrigation is needed today. "
                f"The next irrigation is expected around {earliest.day} {earliest.strftime('%b')}.")
    else:
        text = "The soil holds enough water: no irrigation is needed in the next 7 days based on this estimate."
    if farm.crops:
        confidence = "high" if live and not any_unknown and not soil_unknown and logs else "medium"

    return {
        "farm_id": farm.id, "farm_name": farm.farm_name,
        "daily_liters": round(today_l), "weekly_liters": round(week_l),
        "average_mm_today": round(avg_mm, 2), "confidence": confidence,
        "weather_source": "live" if live else "fallback", "recommendation": text,
        "assumptions": assumptions, "crops": crops_out,
        "crop_demand_liters": round(demand_l),
        "irrigate_today": any_today,
        "next_irrigation_date": earliest.isoformat() if earliest else None,
        "method": "FAO-56 soil water balance (root-zone depletion, Kc x ET0, rain and irrigation); estimate only",
    }


def _baseline_plan(farm: Farm, forecast: dict | None) -> dict:
    daily = (forecast or {}).get("daily", [])
    live = bool(daily) and daily[0].get("et0_mm") is not None
    assumptions: list[str] = []
    if not live:
        assumptions.append(
            f"Live weather unavailable: assumed ET0 of {settings.default_et0_mm} mm/day and no rain."
        )

    crops_out, today_total, week_total, area_total, any_unknown = [], 0.0, 0.0, 0.0, False
    for crop in farm.crops:
        kc, known = kc_for(crop.crop_name, crop.growth_stage)
        if not known:
            any_unknown = True
            assumptions.append(f"No Kc data for '{crop.crop_name}': used a generic crop coefficient.")
        area_ha = float(crop.area_hectares)
        days = []
        for i in range(7):
            if i < len(daily) and daily[i].get("et0_mm") is not None:
                et0, rain = daily[i]["et0_mm"], daily[i].get("rain_mm") or 0.0
            else:
                et0, rain = settings.default_et0_mm, 0.0
            days.append(daily_requirement(kc, et0, rain, area_ha))
        today_total += days[0]["liters"]
        week_total += sum(d["liters"] for d in days)
        area_total += area_ha
        crops_out.append({
            "crop_id": crop.id, "crop": crop.crop_name, "growth_stage": crop.growth_stage,
            "kc": kc, "area_hectares": round(area_ha, 4),
            "et0_mm": round(days[0]["et0_mm"], 2), "etc_mm": round(days[0]["etc_mm"], 2),
            "rain_mm": round(days[0]["rain_mm"], 2), "net_irrigation_mm": round(days[0]["net_mm"], 2),
            "liters_today": round(days[0]["liters"]),
        })

    avg_mm = today_total / (area_total * 10_000) if area_total else 0.0
    if not farm.crops:
        text, confidence = "Add a crop to this farm to get an irrigation estimate.", "low"
    elif today_total <= 0:
        text = ("Rainfall covers the estimated crop demand today, so no irrigation is needed "
                "based on this estimate. Check soil moisture to confirm.")
        confidence = "high" if live and not any_unknown else "medium"
    else:
        text = (f"Estimated crop water need today is about {round(today_total):,} L "
                f"(~{avg_mm:.1f} mm over the cropped area). Irrigate early morning (6-8 AM) to reduce "
                "evaporation losses, and check soil moisture before applying.")
        confidence = "high" if live and not any_unknown else ("medium" if live else "low")

    return {
        "farm_id": farm.id, "farm_name": farm.farm_name,
        "daily_liters": round(today_total), "weekly_liters": round(week_total),
        "average_mm_today": round(avg_mm, 2), "confidence": confidence,
        "weather_source": "live" if live else "fallback", "recommendation": text,
        "assumptions": assumptions, "crops": crops_out,
        "crop_demand_liters": round(today_total),
        "method": "ETc = Kc x ET0 (FAO-56 concept); rain-adjusted; estimate only",
    }