"""Deterministic virtual sensor readings derived from farm and weather estimates."""
import random
import math
from datetime import date

from app.core.config import settings
from app.database_models import Farm
from app.services.irrigation_features import farm_features


def _number(value, default: float) -> float:
    try:
        result = float(value) if value is not None else default
        return result if math.isfinite(result) else default
    except (TypeError, ValueError):
        return default


def simulate_readings(
    farm: Farm,
    forecast: dict | None,
    plan: dict,
    today: date,
    seed: int | None = None,
) -> dict:
    current = (forecast or {}).get("current", {})
    daily = (forecast or {}).get("daily", [])
    day = daily[0] if daily else {}

    if current.get("temperature_c") is not None:
        air_temperature = _number(current.get("temperature_c"), 25.0)
    else:
        air_temperature = 25.0
        low = day.get("t_min")
        high = day.get("t_max")
        if low is not None and high is not None:
            air_temperature = (_number(low, 25.0) + _number(high, 25.0)) / 2
    humidity = _number(current.get("humidity_pct"), 60.0)
    rainfall_value = day.get("rain_mm")
    if rainfall_value is None:
        rainfall_value = current.get("rainfall_mm")
    rainfall = min(300.0, max(0.0, _number(rainfall_value, 0.0)))
    et0 = min(20.0, max(0.0, _number(day.get("et0_mm"), settings.default_et0_mm)))
    context = farm_features(farm)

    crop_rows = plan.get("crops", [])
    moisture_rows = [
        (float(row["soil_water_pct"]), max(float(row.get("area_hectares", 0)), 0.0))
        for row in crop_rows if row.get("soil_water_pct") is not None
    ]
    total_weight = sum(weight for _, weight in moisture_rows)
    if moisture_rows and total_weight:
        soil_moisture = sum(value * weight for value, weight in moisture_rows) / total_weight
        moisture_source = "irrigation_water_balance_estimate"
    else:
        demand = max(_number(plan.get("average_mm_today"), 0.0), 0.0)
        soil_adjustments = {"sandy": -5.0, "clay": 4.0, "loamy": 0.0, "silty": 2.0,
                            "red": -1.0, "black": 3.0, "unknown": 0.0}
        crop_adjustments = {"rice": 7.0, "vegetable": -2.0, "tuber": -1.0}
        soil_moisture = (
            62.0 - min(30.0, demand * 2.0) + min(25.0, rainfall * 1.1)
            + soil_adjustments[context["soil_type"]]
            + crop_adjustments.get(context["crop_type"], 0.0)
        )
        moisture_source = "crop_demand_and_weather_estimate"

    rng = random.Random(seed if seed is not None else (farm.id or 0) * 1_000_003 + today.toordinal())
    soil_moisture = min(100.0, max(0.0, soil_moisture + rng.uniform(-2.0, 2.0)))
    air_temperature = min(60.0, max(-10.0, air_temperature + rng.uniform(-0.5, 0.5)))
    humidity = min(100.0, max(0.0, humidity + rng.uniform(-2.0, 2.0)))
    soil_temperature = (
        air_temperature - 2.5 + (air_temperature - 25.0) * 0.08
        - (soil_moisture - 50.0) * 0.025 + rng.uniform(-0.5, 0.5)
    )
    soil_temperature = min(60.0, max(-10.0, soil_temperature))

    return {
        "farm_id": farm.id,
        "sensor_type": "virtual",
        "simulated": True,
        "mode": "simulated",
        "notice": "Estimated virtual readings; no physical sensors are connected.",
        "farm_context": context,
        "sources": {
            "soil_moisture": moisture_source,
            "weather": "farm_weather_forecast" if forecast else "configured_fallback",
            "et0": "farm_weather_forecast" if day.get("et0_mm") is not None else "configured_fallback",
        },
        "readings": {
            "soil_moisture_pct": round(soil_moisture, 1),
            "air_temperature_c": round(air_temperature, 1),
            "humidity_pct": round(humidity, 1),
            "soil_temperature_c": round(soil_temperature, 1),
            "rainfall_mm": round(rainfall, 1),
            "et0_mm": round(et0, 2),
        },
    }
