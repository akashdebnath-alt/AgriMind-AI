from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.core.timeutil import today_local
from app.db.session import get_db
from app.deps import get_current_user, user_farms
from app.models import Crop, Farm, User
from app.schemas import CropIn, CropOut
from app.services.units import ACRE_IN_HECTARES, to_hectares

router = APIRouter(prefix="/crops", tags=["crops"])


def crop_out(crop: Crop) -> CropOut:
    ha = float(crop.area_hectares)
    return CropOut(
        id=crop.id, farm_id=crop.farm_id, farm_name=crop.farm.farm_name, name=crop.crop_name,
        variety=crop.variety, area=round(ha / ACRE_IN_HECTARES, 2), area_hectares=round(ha, 4),
        planting_date=crop.planting_date, growth_stage=crop.growth_stage, season=crop.season,
        days_since_planting=max(0, (today_local() - crop.planting_date).days),
    )


def _owned_crop(db: Session, user: User, crop_id: int) -> Crop:
    crop = db.scalar(
        select(Crop).join(Farm).where(Crop.id == crop_id, Farm.user_id == user.id).options(joinedload(Crop.farm))
    )
    if crop is None:
        raise HTTPException(404, "Crop not found")
    return crop


def _resolve_farm(db: Session, user: User, body: CropIn) -> Farm:
    farms = user_farms(db, user)
    if body.farm_id is not None:
        match = [f for f in farms if f.id == body.farm_id]
    elif body.farm_name:
        match = [f for f in farms if f.farm_name == body.farm_name]
    else:
        raise HTTPException(422, "Provide farm_id (or farm_name)")
    if not match:
        raise HTTPException(404, "Farm not found - register a farm before adding a crop")
    return match[0]


def _check_date(body: CropIn) -> None:
    if body.planting_date > today_local():
        raise HTTPException(422, "Planting date cannot be in the future")


@router.get("", response_model=list[CropOut])
def list_crops(farm_id: int | None = None, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    q = select(Crop).join(Farm).where(Farm.user_id == user.id).options(joinedload(Crop.farm)).order_by(Crop.id)
    if farm_id is not None:
        q = q.where(Crop.farm_id == farm_id)
    return [crop_out(c) for c in db.scalars(q).all()]


@router.post("", response_model=CropOut, status_code=201)
def create_crop(body: CropIn, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    _check_date(body)
    farm = _resolve_farm(db, user, body)
    crop = Crop(
        farm_id=farm.id, crop_name=body.name, variety=body.variety or "Not specified",
        area_hectares=to_hectares(body.area, body.area_unit), planting_date=body.planting_date,
        growth_stage=body.growth_stage, season=body.season,
    )
    db.add(crop)
    db.commit()
    db.refresh(crop)
    return crop_out(crop)


@router.get("/{crop_id}", response_model=CropOut)
def get_crop(crop_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return crop_out(_owned_crop(db, user, crop_id))


@router.put("/{crop_id}", response_model=CropOut)
def update_crop(crop_id: int, body: CropIn, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    _check_date(body)
    crop = _owned_crop(db, user, crop_id)
    if body.farm_id is not None or body.farm_name:
        crop.farm_id = _resolve_farm(db, user, body).id
    crop.crop_name, crop.variety = body.name, body.variety or "Not specified"
    crop.area_hectares = to_hectares(body.area, body.area_unit)
    crop.planting_date, crop.growth_stage, crop.season = body.planting_date, body.growth_stage, body.season
    db.commit()
    db.refresh(crop)
    return crop_out(crop)


@router.delete("/{crop_id}", status_code=204)
def delete_crop(crop_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    db.delete(_owned_crop(db, user, crop_id))
    db.commit()
