"""FAO-56 soil water balance for one crop (single crop coefficient method).

The idea in plain words
-----------------------
The soil around the roots is like a bucket.
  TAW = size of the bucket: water the plants can use (mm)
  RAW = the part plants can take easily before they start to suffer (mm)
  Dr  = how empty the bucket is ("depletion", mm). 0 means full.

Every day the bucket loses water (crop use = Kc x ET0) and gains water (rain, irrigation).
When Dr reaches RAW it is time to irrigate, and the depth needed to refill is Dr.

All values are typical textbook numbers (FAO Irrigation and Drainage Paper 56) and are
estimates, not a substitute for checking the soil.
"""
from datetime import date, timedelta

from app.services.agronomy import effective_rain

# Water the soil can hold for plants, in mm of water per metre of soil depth.
# Mid-points of FAO-56 Table 19; "black" and "red" are approximations for Indian soil groups.
SOIL_AWC_MM_PER_M = [
    ("black", 160), ("red", 110), ("silt", 175), ("sand", 90), ("loam", 155), ("clay", 160),
]
DEFAULT_AWC = 130  # used when the soil type is unknown

# crop name -> (maximum root depth in metres, p = share of TAW plants can use easily)
# Typical values from FAO-56 Table 22.
CROP_ROOT = {
    "rice": (0.5, 0.20), "paddy": (0.5, 0.20), "wheat": (1.2, 0.55), "tomato": (1.0, 0.40),
    "mustard": (1.0, 0.60), "potato": (0.5, 0.35), "maize": (1.2, 0.55), "corn": (1.2, 0.55),
    "onion": (0.4, 0.30), "cabbage": (0.45, 0.45), "chilli": (0.7, 0.30), "cotton": (1.3, 0.65),
}
DEFAULT_ROOT = (0.8, 0.50)

# Roots grow during the season, so the "bucket" grows too (assumption).
ROOT_FRACTION = {"Initial": 0.4, "Development": 0.7, "Mid-season": 1.0, "Late-season": 1.0, "Harvest": 1.0}
MIN_ROOT_M = 0.25

# Share of the water applied that actually reaches the roots.
EFFICIENCY = [("drip", 0.90), ("sprinkler", 0.75), ("flood", 0.60), ("surface", 0.60), ("manual", 0.60)]
DEFAULT_EFFICIENCY = 0.75


def soil_awc(soil_type: str | None) -> tuple[float, bool]:
    """Returns (mm of available water per metre of soil, soil_type_known)."""
    name = (soil_type or "").lower()
    for key, value in SOIL_AWC_MM_PER_M:
        if key in name:
            return float(value), True
    return float(DEFAULT_AWC), False


def crop_root_params(crop_name: str) -> tuple[float, float, bool]:
    """Returns (max root depth m, p, crop_known)."""
    name = crop_name.lower()
    for key, (zr, p) in CROP_ROOT.items():
        if key in name:
            return zr, p, True
    return DEFAULT_ROOT[0], DEFAULT_ROOT[1], False


def irrigation_efficiency(method: str | None) -> float:
    name = (method or "").lower()
    for key, value in EFFICIENCY:
        if key in name:
            return value
    return DEFAULT_EFFICIENCY


def bucket_size(soil_type: str | None, crop_name: str, stage: str) -> dict:
    """TAW and RAW (mm) for this soil, crop and growth stage."""
    awc, soil_known = soil_awc(soil_type)
    zr_max, p, crop_known = crop_root_params(crop_name)
    root_m = max(MIN_ROOT_M, zr_max * ROOT_FRACTION.get(stage, 1.0))
    taw = awc * root_m
    return {
        "taw_mm": taw, "raw_mm": p * taw, "p": p, "root_depth_m": root_m,
        "soil_known": soil_known, "crop_known": crop_known,
    }


def step(dr_prev: float, taw: float, raw: float, p: float, kc: float,
         et0_mm: float, rain_mm: float, irrigation_net_mm: float = 0.0) -> float:
    """One day of the water balance. Returns the new depletion Dr (mm)."""
    ks = 1.0  # water stress factor: plants slow down their water use when the soil is too dry
    if dr_prev > raw and taw > raw:
        ks = max(0.0, (taw - dr_prev) / ((1.0 - p) * taw))
    etc = ks * kc * et0_mm
    dr = dr_prev - effective_rain(rain_mm) - irrigation_net_mm + etc
    return min(max(dr, 0.0), taw)  # cannot be fuller than full; extra water drains away


def plan_crop(history: list[dict], forecast: list[dict], kc: float, taw: float, raw: float,
              p: float, efficiency: float = DEFAULT_EFFICIENCY) -> dict:
    """Water balance for one crop.

    history  = past days up to yesterday: {"date", "et0_mm", "rain_mm", "irrigation_mm"}
    forecast = today and the coming days: {"date", "et0_mm", "rain_mm", "irrigation_mm" (optional)}
    irrigation_mm is the depth that reached the soil (litres applied / area / 10,000 x efficiency).
    """
    dr = 0.0  # we assume the soil was full at the start of the history window
    for day in history:
        dr = step(dr, taw, raw, p, kc, day["et0_mm"], day["rain_mm"], day.get("irrigation_mm", 0.0))

    dr_now = dr  # how empty the bucket is at the start of today
    events, projection = [], []
    irrigate_today = False
    for i, day in enumerate(forecast):
        dr = max(0.0, dr - day.get("irrigation_mm", 0.0))  # water the farmer already applied that day
        if i == 0:
            dr_now = dr
        if dr >= raw:  # time to irrigate: refill the bucket in the morning
            events.append({"date": day["date"], "net_mm": dr, "gross_mm": dr / efficiency})
            irrigate_today = irrigate_today or i == 0
            dr = 0.0
        dr = step(dr, taw, raw, p, kc, day["et0_mm"], day["rain_mm"])
        projection.append({"date": day["date"], "depletion_mm": round(dr, 1)})

    later = events[1:] if irrigate_today else events
    next_date = later[0]["date"] if later else None
    if next_date is None and forecast and dr >= raw:
        next_date = forecast[-1]["date"] + timedelta(days=1)  # needed right after the forecast ends

    net_today = events[0]["net_mm"] if irrigate_today else 0.0
    gross_today = events[0]["gross_mm"] if irrigate_today else 0.0
    return {
        "kc": kc, "taw_mm": round(taw, 1), "raw_mm": round(raw, 1),
        "depletion_mm": round(dr_now, 1),
        "soil_water_pct": round(100.0 * (taw - dr_now) / taw) if taw else 0,
        "irrigate_today": irrigate_today,
        "net_mm": round(net_today, 1),
        "gross_mm": round(gross_today, 1),
        "next_irrigation_date": next_date,
        "weekly_net_mm": round(sum(e["net_mm"] for e in events), 1),
        "weekly_gross_mm": round(sum(e["gross_mm"] for e in events), 1),
        "projection": projection,
    }


if __name__ == "__main__":
    # Demo: tomato (mid-season) on loamy soil, 21 days of weather with one big rain.
    today = date.today()
    size = bucket_size("Loamy", "Tomato", "Mid-season")
    kc = 1.15
    history = []
    for i in range(21, 0, -1):
        d = today - timedelta(days=i)
        history.append({"date": d, "et0_mm": 5.0, "rain_mm": 30.0 if i == 14 else 0.0, "irrigation_mm": 0.0})
    forecast = [{"date": today + timedelta(days=i), "et0_mm": 5.0, "rain_mm": 0.0} for i in range(7)]
    out = plan_crop(history, forecast, kc, size["taw_mm"], size["raw_mm"], size["p"], irrigation_efficiency("Drip"))
    print(f"Bucket: TAW {out['taw_mm']} mm, RAW {out['raw_mm']} mm (root depth {size['root_depth_m']} m)")
    print(f"Dr today {out['depletion_mm']} mm -> soil water {out['soil_water_pct']}%")
    print(f"Irrigate today? {out['irrigate_today']}   net {out['net_mm']} mm   gross {out['gross_mm']} mm")
    print(f"Next irrigation: {out['next_irrigation_date']}")
    for row in out["projection"]:
        print(f"  {row['date']}  Dr = {row['depletion_mm']} mm")