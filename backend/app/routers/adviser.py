from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.deps import get_current_user, get_owned_farm
from app.models import User
from app.schemas import AdviserIn
from app.services.knowledge import SUGGESTIONS, retrieve

router = APIRouter(prefix="/adviser", tags=["ai-adviser"])


@router.get("/suggestions")
def suggestions(user: User = Depends(get_current_user)):
    return {"suggestions": SUGGESTIONS}


@router.post("/chat")
def chat(body: AdviserIn, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    hits = retrieve(body.message)
    context = ""
    if body.farm_id is not None:
        farm = get_owned_farm(db, user, body.farm_id)
        if farm.crops:
            crops = ", ".join(f"{c.crop_name} ({c.growth_stage})" for c in farm.crops)
            context = f"\n\nFor {farm.farm_name}, you are growing: {crops}."
    if not hits:
        return {
            "reply": ("I do not have verified guidance on that topic yet, so I will not guess. Try asking about "
                      "irrigation timing, yellow leaves, pests, heavy rain or soil moisture, or contact your local "
                      "agriculture extension office."),
            "grounded": False, "sources": [], "mode": "retrieval",
        }
    reply = "\n\n".join(h["text"] for h in hits) + context
    reply += "\n\nThis is general guidance; local conditions and expert advice take priority."
    return {"reply": reply, "grounded": True, "mode": "retrieval",
            "sources": [{"id": h["id"], "title": h["title"]} for h in hits]}
