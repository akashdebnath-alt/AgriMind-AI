from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.deps import get_current_user, get_owned_farm, user_farms
from app.models import Farm, User
from app.schemas import FarmIn, FarmOut
from app.services import weather
from app.services.units import ACRE_IN_HECTARES, from_hectares, to_hectares

router = APIRouter(prefix="/farms", tags=["farms"])


def farm_out(farm: Farm) -> FarmOut:
    ha = float(farm.area_hectares)
    return FarmOut(
        id=farm.id, name=farm.farm_name, location=farm.location,
        area=from_hectares(ha, farm.area_unit), area_unit=farm.area_unit,
        area_hectares=round(ha, 4), area_acres=round(ha / ACRE_IN_HECTARES, 2),
        soil_type=farm.soil_type or "Unknown", crop_count=len(farm.crops),
        latitude=farm.latitude, longitude=farm.longitude,
    )


def _geocode_best_effort(farm: Farm) -> None:
    try:
        coords = weather.geocode(farm.location)
    except Exception:
        coords = None
    farm.latitude, farm.longitude = coords if coords else (None, None)


@router.get("", response_model=list[FarmOut])
def list_farms(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return [farm_out(f) for f in user_farms(db, user)]


@router.post("", response_model=FarmOut, status_code=201)
def create_farm(body: FarmIn, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    farm = Farm(
        user_id=user.id, farm_name=body.name, location=body.location,
        area_hectares=to_hectares(body.area, body.area_unit), area_unit=body.area_unit,
        soil_type=body.soil_type,
    )
    _geocode_best_effort(farm)
    db.add(farm)
    db.commit()
    db.refresh(farm)
    return farm_out(farm)


@router.get("/{farm_id}", response_model=FarmOut)
def get_farm(farm_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return farm_out(get_owned_farm(db, user, farm_id))


@router.put("/{farm_id}", response_model=FarmOut)
def update_farm(farm_id: int, body: FarmIn, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    farm = get_owned_farm(db, user, farm_id)
    location_changed = farm.location != body.location
    farm.farm_name, farm.location = body.name, body.location
    farm.area_hectares, farm.area_unit = to_hectares(body.area, body.area_unit), body.area_unit
    farm.soil_type = body.soil_type
    if location_changed:
        _geocode_best_effort(farm)
    db.commit()
    db.refresh(farm)
    return farm_out(farm)


@router.delete("/{farm_id}", status_code=204)
def delete_farm(farm_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    """Deletes the farm and its crops/irrigation records (matches the app's delete dialog)."""
    db.delete(get_owned_farm(db, user, farm_id))
    db.commit()
