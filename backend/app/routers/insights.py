from collections import defaultdict
from datetime import timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.time_utils import now_local, today_local
from app.db.session import get_db
from app.dependencies import get_current_user, user_farms
from app.database_models import Farm, IrrigationLog, User
from app.services import weather
from app.services.irrigation_planner import plan_for_farm_db
from app.services.area_units import ACRE_IN_HECTARES

router = APIRouter(prefix="/insights", tags=["insights"])


@router.get("")
def insights(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    farms = user_farms(db, user)
    crops = [c for f in farms for c in f.crops]
    farm_ha = sum(float(f.area_hectares) for f in farms)
    crop_ha = sum(float(c.area_hectares) for c in crops)

    now = now_local()
    period_start = (now - timedelta(days=6)).replace(hour=0, minute=0, second=0, microsecond=0)
    period_end = now
    logs = db.scalars(
        select(IrrigationLog).join(Farm)
        .where(Farm.user_id == user.id, IrrigationLog.status == "completed",
               IrrigationLog.occurred_at >= period_start)
    ).all()
    per_date = defaultdict(float)
    for l in logs:
        per_date[l.occurred_at.date()] += l.amount_liters or 0.0
    used = sum(per_date.values())
    activity = [
        {
            "day": (period_start.date() + timedelta(days=i)).strftime("%a"),
            "date": (period_start.date() + timedelta(days=i)).isoformat(),
            "liters": round(per_date[period_start.date() + timedelta(days=i)]),
        }
        for i in range(7)
    ]
    activity_peak = max((item["liters"] for item in activity), default=0)

    plans, rain_soon = [], False
    for f in farms:
        fc = weather.forecast_for_farm(f, db)
        plans.append(plan_for_farm_db(db, f))
        if fc:
            rain_soon = rain_soon or any((d.get("rain_mm") or 0) >= 5 for d in fc["daily"][:2])
    recommended = sum(p["weekly_liters"] for p in plans)
    ratio = min(1.0, used / recommended) if recommended else None

    by_crop = defaultdict(float)
    for c in crops:
        by_crop[c.crop_name.strip().title()] += float(c.area_hectares)

    return {
        "overview": {
            "total_farms": len(farms), "farm_area_acres": round(farm_ha / ACRE_IN_HECTARES, 2),
            "cultivated_area_acres": round(crop_ha / ACRE_IN_HECTARES, 2),
            "active_crops": len(crops), "water_used_liters": round(used),
        },
        "water_usage": {
            "used_liters": round(used), "recommended_weekly_liters": recommended,
            "used_ratio": None if ratio is None else round(ratio, 2),
            "remaining_ratio": None if ratio is None else round(1 - ratio, 2),
            "period_start": period_start.date().isoformat(),
            "period_end": period_end.date().isoformat(),
            "period_label": "Last 7 days",
            "basis": "Completed irrigation logs in the last 7 days vs. FAO-56 estimated weekly irrigation requirement",
        },
        "crop_distribution": [
            {"name": n, "area_acres": round(ha / ACRE_IN_HECTARES, 2),
             "share": round(ha / crop_ha, 2) if crop_ha else 0}
            for n, ha in sorted(by_crop.items(), key=lambda kv: -kv[1])
        ],
        "weekly_activity": [
            {
                "day": item["day"],
                "date": item["date"],
                "liters": item["liters"],
                "value": round(item["liters"] / activity_peak, 2) if activity_peak else 0,
            }
            for item in activity
        ],
        "recommendations": recommendations(farms, crops, rain_soon, bool(logs)),
    }


def recommendations(farms, crops, rain_soon, irrigated_this_week):
    recs = []
    if not farms:
        recs.append({"icon": "farm", "title": "Register a farm", "description": "Add your farm to unlock estimates."})
    elif not crops:
        recs.append({"icon": "crop", "title": "Add your crops", "description": "Crop stage and area drive irrigation estimates."})
    if rain_soon:
        recs.append({"icon": "weather", "title": "Rain expected soon",
                     "description": "Consider deferring irrigation; 5 mm or more is forecast within 2 days."})
    if crops and not irrigated_this_week:
        recs.append({"icon": "water", "title": "No irrigation logged in the last 7 days",
                     "description": "Check soil moisture and log irrigation so usage insights stay accurate."})
    recs += [
        {"icon": "water", "title": "Monitor soil moisture", "description": "Check soil moisture before your next irrigation session."},
        {"icon": "weather", "title": "Check weather conditions", "description": "Review rainfall forecasts before planning irrigation."},
        {"icon": "crop", "title": "Track crop growth", "description": "Keep crop planting dates and growth stages updated."},
    ]
    return recs[:5]
