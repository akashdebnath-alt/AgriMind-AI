from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.timeutil import now_local
from app.db.session import get_db
from app.deps import get_current_user, user_farms
from app.models import Farm, IrrigationLog, User
from app.services.units import ACRE_IN_HECTARES

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("")
def dashboard(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    farms = user_farms(db, user)
    total_ha = sum(float(f.area_hectares) for f in farms)
    start = now_local().replace(hour=0, minute=0, second=0, microsecond=0)
    done = db.scalar(
        select(IrrigationLog.id).join(Farm)
        .where(Farm.user_id == user.id, IrrigationLog.status == "completed", IrrigationLog.occurred_at >= start)
        .limit(1)
    )
    return {
        "farm_count": len(farms),
        "total_area_acres": round(total_ha / ACRE_IN_HECTARES, 2),
        "total_area_hectares": round(total_ha, 2),
        "crop_count": sum(len(f.crops) for f in farms),
        "irrigation_status": "Completed" if done else "Pending",
    }
