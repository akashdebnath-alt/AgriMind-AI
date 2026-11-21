"""Live weather via Open-Meteo (free, no API key). Returns None when unavailable."""
import time

import httpx
from sqlalchemy.orm import Session

from app.core.config import settings
from app.database_models import Farm

_CACHE: dict[tuple, tuple[float, dict | None]] = {}
_OK_TTL, _FAIL_TTL = 1800, 120

_WMO = {
    0: "Clear sky", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
    45: "Fog", 48: "Fog", 51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle",
    61: "Light rain", 63: "Rain", 65: "Heavy rain", 71: "Light snow", 73: "Snow", 75: "Heavy snow",
    80: "Rain showers", 81: "Rain showers", 82: "Violent rain showers",
    95: "Thunderstorm", 96: "Thunderstorm with hail", 99: "Thunderstorm with hail",
}


def condition_text(code: int | None) -> str:
    return _WMO.get(code, "Unknown") if code is not None else "Unknown"


def geocode(name: str) -> tuple[float, float] | None:
    """Best-effort: try the full text, then each comma-separated part from the end."""
    parts = [p.strip() for p in name.split(",") if p.strip()]
    candidates = [name.strip()] + list(reversed(parts)) if len(parts) > 1 else [name.strip()]
    for cand in candidates[:4]:
        try:
            r = httpx.get(
                "https://geocoding-api.open-meteo.com/v1/search",
                params={"name": cand, "count": 1},
                timeout=settings.weather_timeout_seconds,
            )
            results = r.json().get("results") or []
            if results:
                return float(results[0]["latitude"]), float(results[0]["longitude"])
        except Exception:
            continue
    return None


def get_forecast(lat: float, lon: float) -> dict | None:
    key = (round(lat, 2), round(lon, 2))
    hit = _CACHE.get(key)
    if hit and hit[0] > time.time():
        return hit[1]
    data = None
    try:
        r = httpx.get(
            "https://api.open-meteo.com/v1/forecast",
            params={
                "latitude": lat, "longitude": lon, "timezone": "auto", "forecast_days": 7,
                "current": "temperature_2m,relative_humidity_2m,apparent_temperature,"
                           "wind_speed_10m,cloud_cover,precipitation,weather_code",
                "daily": "weather_code,temperature_2m_max,temperature_2m_min,"
                         "precipitation_sum,et0_fao_evapotranspiration",
            },
            timeout=settings.weather_timeout_seconds,
        )
        r.raise_for_status()
        j = r.json()
        cur, d = j["current"], j["daily"]
        data = {
            "current": {
                "temperature_c": cur["temperature_2m"],
                "feels_like_c": cur["apparent_temperature"],
                "humidity_pct": cur["relative_humidity_2m"],
                "wind_kmh": cur["wind_speed_10m"],
                "cloud_cover_pct": cur["cloud_cover"],
                "rainfall_mm": cur["precipitation"],
                "condition": condition_text(cur["weather_code"]),
            },
            "daily": [
                {
                    "date": d["time"][i],
                    "condition": condition_text(d["weather_code"][i]),
                    "t_max": d["temperature_2m_max"][i],
                    "t_min": d["temperature_2m_min"][i],
                    "rain_mm": d["precipitation_sum"][i],
                    "et0_mm": d["et0_fao_evapotranspiration"][i],
                }
                for i in range(len(d["time"]))
            ],
        }
    except Exception:
        data = None
    _CACHE[key] = (time.time() + (_OK_TTL if data else _FAIL_TTL), data)
    return data


def forecast_for_farm(farm: Farm, db: Session) -> dict | None:
    if farm.latitude is None or farm.longitude is None:
        coords = geocode(farm.location)
        if coords is None:
            return None
        farm.latitude, farm.longitude = coords
        db.commit()
    return get_forecast(farm.latitude, farm.longitude)
