from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.security import decode_token
from app.db.session import get_db
from app.database_models import Farm, User

bearer = HTTPBearer(auto_error=False)


def get_current_user(
    creds: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    unauthorized = HTTPException(
        status.HTTP_401_UNAUTHORIZED, "Not authenticated", headers={"WWW-Authenticate": "Bearer"}
    )
    if creds is None:
        raise unauthorized
    user_id = decode_token(creds.credentials)
    user = db.get(User, user_id) if user_id else None
    if user is None:
        raise unauthorized
    return user


def get_owned_farm(db: Session, user: User, farm_id: int) -> Farm:
    farm = db.scalar(
        select(Farm).where(Farm.id == farm_id, Farm.user_id == user.id).options(selectinload(Farm.crops))
    )
    if farm is None:
        raise HTTPException(404, "Farm not found")
    return farm


def user_farms(db: Session, user: User, farm_id: int | None = None) -> list[Farm]:
    q = select(Farm).where(Farm.user_id == user.id).options(selectinload(Farm.crops)).order_by(Farm.id)
    if farm_id is not None:
        q = q.where(Farm.id == farm_id)
    farms = list(db.scalars(q).all())
    if farm_id is not None and not farms:
        raise HTTPException(404, "Farm not found")
    return farms
