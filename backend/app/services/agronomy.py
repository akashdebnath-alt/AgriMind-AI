"""Scientific baseline: ETc = Kc x ET0 (FAO-56 concept), as described in the project report.

Kc values below are simplified approximations of FAO-56 table values mapped onto the
app's five growth stages. They are a transparent baseline, not a substitute for local
agronomic advice.
"""
STAGES = ["Initial", "Development", "Mid-season", "Late-season", "Harvest"]

KC_TABLE: dict[str, list[float]] = {
    "rice": [1.05, 1.10, 1.20, 0.90, 0.60],
    "paddy": [1.05, 1.10, 1.20, 0.90, 0.60],
    "wheat": [0.30, 0.70, 1.15, 0.40, 0.25],
    "tomato": [0.60, 0.80, 1.15, 0.80, 0.70],
    "mustard": [0.35, 0.75, 1.10, 0.35, 0.30],
    "potato": [0.50, 0.80, 1.15, 0.75, 0.50],
    "maize": [0.30, 0.80, 1.20, 0.60, 0.35],
    "corn": [0.30, 0.80, 1.20, 0.60, 0.35],
    "onion": [0.50, 0.75, 1.05, 0.85, 0.75],
    "cabbage": [0.70, 0.80, 1.05, 0.95, 0.90],
    "chilli": [0.60, 0.80, 1.05, 0.90, 0.80],
    "cotton": [0.35, 0.75, 1.15, 0.70, 0.50],
}
DEFAULT_KC = [0.50, 0.80, 1.10, 0.80, 0.50]


def kc_for(crop_name: str, stage: str) -> tuple[float, bool]:
    """Returns (kc, crop_known)."""
    idx = STAGES.index(stage) if stage in STAGES else 2
    name = crop_name.lower()
    for key, values in KC_TABLE.items():
        if key in name:
            return values[idx], True
    return DEFAULT_KC[idx], False


def effective_rain(rain_mm: float) -> float:
    """Simplified: ignore trace rain, count 80% of the rest as usable."""
    return 0.0 if rain_mm < 1.0 else 0.8 * rain_mm


def daily_requirement(kc: float, et0_mm: float, rain_mm: float, area_ha: float) -> dict:
    etc = kc * et0_mm
    net = max(0.0, etc - effective_rain(rain_mm))
    # 1 mm over 1 ha = 10 m3 = 10,000 L
    liters = net * float(area_ha) * 10_000
    return {"et0_mm": et0_mm, "etc_mm": etc, "rain_mm": rain_mm, "net_mm": net, "liters": liters}
