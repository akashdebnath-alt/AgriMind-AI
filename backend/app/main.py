import base64
import hashlib
import hmac
import json
import os
import time
from datetime import date
from pathlib import Path

from fastapi import Depends, FastAPI, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from app.db.database import engine

app = FastAPI(
    title="AgriMind AI API",
    description="Backend API for smart agriculture and irrigation management.",
    version="1.0.0",
)

# Lets the Flutter app talk to this backend while you develop.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------------------------------------------------
# Secret key (created automatically the first time you run)
# ------------------------------------------------------------
SECRET_FILE = Path(__file__).resolve().parents[1] / ".secret_key"
if not SECRET_FILE.exists():
    SECRET_FILE.write_text(base64.urlsafe_b64encode(os.urandom(48)).decode())
SECRET = SECRET_FILE.read_text().strip().encode()


# ------------------------------------------------------------
# Passwords and login tokens (Python built-ins only)
# ------------------------------------------------------------
def hash_password(password: str) -> str:
    salt = os.urandom(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 600_000)
    return f"{salt.hex()}${digest.hex()}"


def check_password(password: str, stored: str) -> bool:
    try:
        salt_hex, digest_hex = stored.split("$")
        digest = hashlib.pbkdf2_hmac(
            "sha256", password.encode(), bytes.fromhex(salt_hex), 600_000
        )
        return hmac.compare_digest(digest.hex(), digest_hex)
    except ValueError:
        return False


def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")


def _unb64(text_value: str) -> bytes:
    return base64.urlsafe_b64decode(text_value + "=" * (-len(text_value) % 4))


def make_token(user_id: int) -> str:
    payload = {"uid": user_id, "exp": int(time.time()) + 7 * 24 * 3600}
    body = _b64(json.dumps(payload).encode())
    sig = _b64(hmac.new(SECRET, body.encode(), hashlib.sha256).digest())
    return f"{body}.{sig}"


def read_token(token: str):
    try:
        body, sig = token.split(".")
        expected = _b64(hmac.new(SECRET, body.encode(), hashlib.sha256).digest())
        if not hmac.compare_digest(sig, expected):
            return None
        data = json.loads(_unb64(body))
        if data["exp"] < time.time():
            return None
        return int(data["uid"])
    except Exception:
        return None


bearer = HTTPBearer(auto_error=False)


def current_user_id(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
) -> int:
    if credentials is not None:
        user_id = read_token(credentials.credentials)
        if user_id is not None:
            return user_id
    raise HTTPException(status_code=401, detail="Please log in again.")


# ------------------------------------------------------------
# Data shapes
# ------------------------------------------------------------
class RegisterIn(BaseModel):
    full_name: str = Field(min_length=2, max_length=100)
    email: str = Field(pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$", max_length=150)
    phone: str | None = Field(default=None, max_length=20)
    password: str = Field(min_length=8, max_length=128)


class LoginIn(BaseModel):
    email: str
    password: str


class FarmIn(BaseModel):
    farm_name: str = Field(min_length=1, max_length=100)
    location: str = Field(min_length=1, max_length=150)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    elevation_m: float | None = 0
    area_hectares: float = Field(gt=0)
    soil_type: str | None = Field(default=None, max_length=50)


class CropIn(BaseModel):
    farm_id: int
    crop_name: str = Field(min_length=1, max_length=60)
    planting_date: date
    irrigation_method: str | None = Field(default="drip", max_length=30)
    area_hectares: float | None = Field(default=None, gt=0)


# ------------------------------------------------------------
# Basic checks
# ------------------------------------------------------------
@app.get("/")
def home():
    return {"message": "Welcome to AgriMind AI Backend", "status": "running"}


@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "AgriMind AI"}


@app.get("/db-health")
def database_health():
    try:
        with engine.connect() as connection:
            name = connection.execute(text("SELECT DATABASE()")).scalar_one()
        return {"status": "connected", "database": name}
    except SQLAlchemyError:
        raise HTTPException(
            status_code=503,
            detail="Could not connect to the database. Check backend configuration.",
        )


# ------------------------------------------------------------
# Register / Login
# ------------------------------------------------------------
@app.post("/auth/register", status_code=201, tags=["Auth"])
def register(data: RegisterIn):
    email = data.email.strip().lower()
    password_hash = hash_password(data.password)
    try:
        with engine.begin() as conn:
            result = conn.execute(
                text(
                    "INSERT INTO users (full_name, email, phone, password_hash) "
                    "VALUES (:name, :email, :phone, :hash)"
                ),
                {
                    "name": data.full_name.strip(),
                    "email": email,
                    "phone": data.phone,
                    "hash": password_hash,
                },
            )
            user_id = result.lastrowid
    except IntegrityError:
        raise HTTPException(status_code=409, detail="This email is already registered.")

    return {
        "access_token": make_token(user_id),
        "token_type": "bearer",
        "user": {
            "user_id": user_id,
            "full_name": data.full_name.strip(),
            "email": email,
            "phone": data.phone,
        },
    }


@app.post("/auth/login", tags=["Auth"])
def login(data: LoginIn):
    email = data.email.strip().lower()
    with engine.connect() as conn:
        row = conn.execute(
            text(
                "SELECT user_id, full_name, email, phone, password_hash "
                "FROM users WHERE email = :email"
            ),
            {"email": email},
        ).first()

    if row is None or not check_password(data.password, row.password_hash):
        raise HTTPException(status_code=401, detail="Wrong email or password.")

    return {
        "access_token": make_token(row.user_id),
        "token_type": "bearer",
        "user": {
            "user_id": row.user_id,
            "full_name": row.full_name,
            "email": row.email,
            "phone": row.phone,
        },
    }


# ------------------------------------------------------------
# Farms
# ------------------------------------------------------------
FARM_COLS = (
    "farm_id, farm_name, location, latitude, longitude, "
    "elevation_m, area_hectares, soil_type"
)


def farm_belongs_to(conn, farm_id: int, user_id: int) -> bool:
    row = conn.execute(
        text("SELECT 1 FROM farms WHERE farm_id = :f AND user_id = :u"),
        {"f": farm_id, "u": user_id},
    ).first()
    return row is not None


@app.get("/farms", tags=["Farms"])
def list_farms(user_id: int = Depends(current_user_id)):
    with engine.connect() as conn:
        rows = conn.execute(
            text(f"SELECT {FARM_COLS} FROM farms WHERE user_id = :u ORDER BY farm_id"),
            {"u": user_id},
        ).all()
    return [dict(r._mapping) for r in rows]


@app.post("/farms", status_code=201, tags=["Farms"])
def create_farm(data: FarmIn, user_id: int = Depends(current_user_id)):
    with engine.begin() as conn:
        result = conn.execute(
            text(
                "INSERT INTO farms (user_id, farm_name, location, latitude, "
                "longitude, elevation_m, area_hectares, soil_type) VALUES "
                "(:user_id, :farm_name, :location, :latitude, :longitude, "
                ":elevation_m, :area_hectares, :soil_type)"
            ),
            {**data.model_dump(), "user_id": user_id},
        )
        farm_id = result.lastrowid
    return {"farm_id": farm_id, **data.model_dump()}


@app.put("/farms/{farm_id}", tags=["Farms"])
def update_farm(farm_id: int, data: FarmIn, user_id: int = Depends(current_user_id)):
    with engine.begin() as conn:
        if not farm_belongs_to(conn, farm_id, user_id):
            raise HTTPException(status_code=404, detail="Farm not found.")
        conn.execute(
            text(
                "UPDATE farms SET farm_name = :farm_name, location = :location, "
                "latitude = :latitude, longitude = :longitude, "
                "elevation_m = :elevation_m, area_hectares = :area_hectares, "
                "soil_type = :soil_type WHERE farm_id = :farm_id"
            ),
            {**data.model_dump(), "farm_id": farm_id},
        )
    return {"farm_id": farm_id, **data.model_dump()}


@app.delete("/farms/{farm_id}", status_code=204, tags=["Farms"])
def delete_farm(farm_id: int, user_id: int = Depends(current_user_id)):
    with engine.begin() as conn:
        if not farm_belongs_to(conn, farm_id, user_id):
            raise HTTPException(status_code=404, detail="Farm not found.")
        conn.execute(text("DELETE FROM farms WHERE farm_id = :f"), {"f": farm_id})
    return Response(status_code=204)


# ------------------------------------------------------------
# Crops
# ------------------------------------------------------------
CROP_COLS = (
    "c.crop_id, c.farm_id, c.crop_name, c.planting_date, "
    "c.irrigation_method, c.area_hectares"
)


def crop_belongs_to(conn, crop_id: int, user_id: int) -> bool:
    row = conn.execute(
        text(
            "SELECT 1 FROM crops c JOIN farms f ON f.farm_id = c.farm_id "
            "WHERE c.crop_id = :c AND f.user_id = :u"
        ),
        {"c": crop_id, "u": user_id},
    ).first()
    return row is not None


@app.get("/crops", tags=["Crops"])
def list_crops(user_id: int = Depends(current_user_id)):
    with engine.connect() as conn:
        rows = conn.execute(
            text(
                f"SELECT {CROP_COLS} FROM crops c "
                "JOIN farms f ON f.farm_id = c.farm_id "
                "WHERE f.user_id = :u ORDER BY c.crop_id"
            ),
            {"u": user_id},
        ).all()
    return [dict(r._mapping) for r in rows]


@app.post("/crops", status_code=201, tags=["Crops"])
def create_crop(data: CropIn, user_id: int = Depends(current_user_id)):
    with engine.begin() as conn:
        if not farm_belongs_to(conn, data.farm_id, user_id):
            raise HTTPException(status_code=404, detail="Farm not found.")
        result = conn.execute(
            text(
                "INSERT INTO crops (farm_id, crop_name, planting_date, "
                "irrigation_method, area_hectares) VALUES "
                "(:farm_id, :crop_name, :planting_date, :irrigation_method, "
                ":area_hectares)"
            ),
            data.model_dump(),
        )
        crop_id = result.lastrowid
    return {"crop_id": crop_id, **data.model_dump()}


@app.put("/crops/{crop_id}", tags=["Crops"])
def update_crop(crop_id: int, data: CropIn, user_id: int = Depends(current_user_id)):
    with engine.begin() as conn:
        if not crop_belongs_to(conn, crop_id, user_id):
            raise HTTPException(status_code=404, detail="Crop not found.")
        if not farm_belongs_to(conn, data.farm_id, user_id):
            raise HTTPException(status_code=404, detail="Farm not found.")
        conn.execute(
            text(
                "UPDATE crops SET farm_id = :farm_id, crop_name = :crop_name, "
                "planting_date = :planting_date, "
                "irrigation_method = :irrigation_method, "
                "area_hectares = :area_hectares WHERE crop_id = :crop_id"
            ),
            {**data.model_dump(), "crop_id": crop_id},
        )
    return {"crop_id": crop_id, **data.model_dump()}


@app.delete("/crops/{crop_id}", status_code=204, tags=["Crops"])
def delete_crop(crop_id: int, user_id: int = Depends(current_user_id)):
    with engine.begin() as conn:
        if not crop_belongs_to(conn, crop_id, user_id):
            raise HTTPException(status_code=404, detail="Crop not found.")
        conn.execute(text("DELETE FROM crops WHERE crop_id = :c"), {"c": crop_id})
    return Response(status_code=204)