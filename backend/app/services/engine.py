from app.core.config import settings
from app.models import Farm
from app.services.agronomy import daily_requirement, kc_for


def plan_for_farm(farm: Farm, forecast: dict | None) -> dict:
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
        "method": "ETc = Kc x ET0 (FAO-56 concept); rain-adjusted; estimate only",
    }
