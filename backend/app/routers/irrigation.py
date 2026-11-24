from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.time_utils import now_local, today_local
from app.db.session import get_db
from app.dependencies import get_current_user, get_owned_farm, user_farms
from app.database_models import Farm, IrrigationLog, IrrigationPrediction, User
from app.api_schemas import IrrigationLogIn, RecommendationIn, ScheduleIn
from app.services import weather
from app.services.irrigation_planner import plan_for_farm_db, suggest_next

router = APIRouter(prefix="/irrigation", tags=["irrigation"])


def date_label(dt) -> str:
    d = dt.date()
    if d == today_local():
        return "Today"
    if d == today_local() - timedelta(days=1):
        return "Yesterday"
    return f"{d.day} {d.strftime('%b %Y')}"


def log_out(log: IrrigationLog) -> dict:
    when = log.occurred_at or log.scheduled_for
    return {
        "id": log.id, "farm_id": log.farm_id, "farm_name": log.farm.farm_name,
        "status": log.status, "amount_liters": log.amount_liters, "method": log.method,
        "occurred_at": log.occurred_at, "scheduled_for": log.scheduled_for,
        "date_label": date_label(when) if when else None,
    }


def _plan(db: Session, farm: Farm) -> dict:
    return plan_for_farm_db(db, farm)

def _user_logs(db: Session, user: User, farm_id: int | None, status: str):
    q = select(IrrigationLog).join(Farm).where(Farm.user_id == user.id, IrrigationLog.status == status)
    if farm_id is not None:
        q = q.where(IrrigationLog.farm_id == farm_id)
    return q


@router.get("/overview")
def overview(farm_id: int | None = None, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    farms = user_farms(db, user, farm_id)
    plans = [_plan(db, f) for f in farms]
    daily = sum(p["daily_liters"] for p in plans)
    weekly = sum(p["weekly_liters"] for p in plans)
    daily_crop_demand = sum(p["crop_demand_liters"] for p in plans)
    weekly_crop_demand = sum(p.get("weekly_crop_demand_liters", p["crop_demand_liters"]) for p in plans)
    assumptions = sorted({a for p in plans for a in p["assumptions"]})

    today_start = now_local().replace(hour=0, minute=0, second=0, microsecond=0)
    done_today = db.scalars(
        _user_logs(db, user, farm_id, "completed").where(IrrigationLog.occurred_at >= today_start)
    ).first()
    upcoming = db.scalars(
        _user_logs(db, user, farm_id, "scheduled")
        .where(IrrigationLog.scheduled_for >= now_local()).order_by(IrrigationLog.scheduled_for)
    ).first()
    history = db.scalars(
        _user_logs(db, user, farm_id, "completed").order_by(IrrigationLog.occurred_at.desc()).limit(10)
    ).all()

    if upcoming:
        nxt = {"scheduled": True, "when": upcoming.scheduled_for, "label": date_label(upcoming.scheduled_for),
               "amount_liters": upcoming.amount_liters}
    elif done_today:
        nxt = {"scheduled": False, "label": "Next irrigation not scheduled"}
    else:
        nxt = suggest_next(plans)

    return {
        "status": "Completed Today" if done_today else "Needs Monitoring",
        "irrigated_today": done_today is not None,
        "daily_estimate_liters": daily, "weekly_estimate_liters": weekly,
        "daily_crop_demand_liters": daily_crop_demand,
        "weekly_crop_demand_liters": weekly_crop_demand,
        "is_estimate": True, "assumptions": assumptions,
        "next_irrigation": nxt, "history": [log_out(h) for h in history],
        "note": "Estimates use crop stage, area, weather and rainfall (ETc = Kc x ET0).",
    }


@router.post("/recommendations", status_code=201)
def create_recommendation(body: RecommendationIn, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    farm = get_owned_farm(db, user, body.farm_id)
    plan = _plan(db, farm)
    db.add(IrrigationPrediction(
        farm_id=farm.id, prediction_date=today_local(), irrigation_mm=plan["average_mm_today"],
        volume_liters=plan["daily_liters"], confidence=plan["confidence"], recommendation=plan["recommendation"],
    ))
    db.commit()
    return plan


@router.get("/recommendations")
def recommendation_history(farm_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    get_owned_farm(db, user, farm_id)
    rows = db.scalars(
        select(IrrigationPrediction).where(IrrigationPrediction.farm_id == farm_id)
        .order_by(IrrigationPrediction.id.desc()).limit(50)
    ).all()
    return [
        {"id": r.id, "prediction_date": r.prediction_date, "irrigation_mm": r.irrigation_mm,
         "volume_liters": r.volume_liters, "confidence": r.confidence, "recommendation": r.recommendation}
        for r in rows
    ]


@router.post("/logs", status_code=201)
def mark_irrigated(body: IrrigationLogIn, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    farm = get_owned_farm(db, user, body.farm_id)
    amount = body.amount_liters
    if amount is None:
        plan = _plan(db, farm)
        amount = plan["daily_liters"]
        if amount is None or amount <= 0:
            raise HTTPException(
                400,
                "No irrigation is needed today. Enter an amount to log anyway.",
            )
    log = IrrigationLog(farm_id=farm.id, amount_liters=amount, method=body.method,
                        status="completed", occurred_at=now_local())
    db.add(log)
    db.commit()
    db.refresh(log)
    return log_out(log)


@router.get("/logs")
def list_logs(farm_id: int | None = None, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    q = (select(IrrigationLog).join(Farm).where(Farm.user_id == user.id)
         .order_by(IrrigationLog.id.desc()).limit(100))
    if farm_id is not None:
        q = q.where(IrrigationLog.farm_id == farm_id)
    return [log_out(l) for l in db.scalars(q).all()]


@router.post("/schedule", status_code=201)
def schedule_irrigation(body: ScheduleIn, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    farm = get_owned_farm(db, user, body.farm_id)
    when = body.scheduled_for.replace(tzinfo=None)
    if when <= now_local():
        raise HTTPException(422, "scheduled_for must be in the future")
    log = IrrigationLog(farm_id=farm.id, amount_liters=body.amount_liters, method=body.method,
                        status="scheduled", scheduled_for=when)
    db.add(log)
    db.commit()
    db.refresh(log)
    return log_out(log)


@router.delete("/logs/{log_id}", status_code=204)
def delete_log(log_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    log = db.scalar(select(IrrigationLog).join(Farm).where(IrrigationLog.id == log_id, Farm.user_id == user.id))
    if log is None:
        raise HTTPException(404, "Record not found")
    db.delete(log)
    db.commit()
