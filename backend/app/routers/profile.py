from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.dependencies import get_current_user
from app.database_models import User
from app.api_schemas import ProfileUpdate, UserOut

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("", response_model=UserOut)
def get_profile(user: User = Depends(get_current_user)):
    return user


@router.patch("", response_model=UserOut)
def update_profile(body: ProfileUpdate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    for field, value in body.model_dump(exclude_unset=True).items():
        if value is not None or field == "full_name":
            setattr(user, field, value)
    db.commit()
    db.refresh(user)
    return user
