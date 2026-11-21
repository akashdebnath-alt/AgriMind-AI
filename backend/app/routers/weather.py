from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.dependencies import get_current_user, user_farms
from app.database_models import User
from app.services import weather as weather_service

router = APIRouter(prefix="/weather", tags=["weather"])


@router.get("")
def farm_weather(farm_id: int | None = None, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
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
        "source": "Open-Meteo", "current": data["current"],
        "today": {"high_c": today["t_max"], "low_c": today["t_min"]},
        "forecast": data["daily"][:5],
    }
