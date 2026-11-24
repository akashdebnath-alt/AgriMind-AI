from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.dependencies import get_current_user, user_farms
from app.database_models import User
from app.services import weather as weather_service

router = APIRouter(prefix="/weather", tags=["weather"])


@router.get("")
def farm_weather(
    farm_id: int | None = None,
    lat: float | None = None,
    lon: float | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    # Current-location mode: the app sends the device's coordinates, no farm needed.
    if lat is not None and lon is not None:
        if not (-90 <= lat <= 90 and -180 <= lon <= 180):
            raise HTTPException(422, "Invalid coordinates")
        data = weather_service.get_forecast(lat, lon)
        if data is None:
            raise HTTPException(503, "Weather data is currently unavailable for your location")
        today = data["daily"][0]
        return {
            "farm_id": None, "farm_name": None,
            "location": weather_service.reverse_geocode(lat, lon) or f"{lat:.2f}, {lon:.2f}",
            "is_current_location": True,
            "source": "Open-Meteo", "current": data["current"],
            "today": {"high_c": today["t_max"], "low_c": today["t_min"]},
            "forecast": data["daily"][:5],
        }

    farms = user_farms(db, user, farm_id)
    if not farms:
        raise HTTPException(404, "Register a farm to see weather for your farming area")
    farm = farms[0]
    data = weather_service.forecast_for_farm(farm, db)
    if data is None:
        raise HTTPException(503, "Weather data is currently unavailable for this farm location")
    today = data["daily"][0]
    return {
        "farm_id": farm.id, "farm_name": farm.farm_name, "location": farm.location,
        "is_current_location": False,
        "source": "Open-Meteo", "current": data["current"],
        "today": {"high_c": today["t_max"], "low_c": today["t_min"]},
        "forecast": data["daily"][:5],
    }
