from datetime import date, datetime
from typing import Annotated, Literal

from pydantic import BaseModel, EmailStr, Field, StringConstraints

Name100 = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=100)]
Name150 = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=150)]

AreaUnit = Literal["Acres", "Hectares"]
GrowthStage = Literal["Initial", "Development", "Mid-season", "Late-season", "Harvest"]
Season = Literal["Kharif", "Rabi", "Zaid", "Other"]
Language = Literal["English", "Hindi", "Bengali"]


# ---------- auth / profile ----------
class RegisterIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str | None = Field(default=None, max_length=100)


class LoginIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class UserOut(BaseModel):
    id: int
    email: str
    full_name: str | None
    language: str
    notifications_enabled: bool
    weather_alerts_enabled: bool

    model_config = {"from_attributes": True}


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class ChangePasswordIn(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8, max_length=128)


class ForgotPasswordIn(BaseModel):
    email: EmailStr


class ProfileUpdate(BaseModel):
    full_name: str | None = Field(default=None, max_length=100)
    language: Language | None = None
    notifications_enabled: bool | None = None
    weather_alerts_enabled: bool | None = None


# ---------- farms ----------
class FarmIn(BaseModel):
    name: Name100
    location: Name150
    area: float = Field(gt=0, le=10_000_000)
    area_unit: AreaUnit = "Acres"
    soil_type: str = Field(default="Unknown", max_length=50)


class FarmOut(BaseModel):
    id: int
    name: str
    location: str
    area: float
    area_unit: str
    area_hectares: float
    area_acres: float
    soil_type: str
    crop_count: int
    latitude: float | None
    longitude: float | None


# ---------- crops ----------
class CropIn(BaseModel):
    farm_id: int | None = None
    farm_name: str | None = None  # convenience: the current Flutter UI selects farms by name
    name: Name100
    variety: str = Field(default="Not specified", max_length=100)
    area: float = Field(gt=0, le=10_000_000)
    area_unit: AreaUnit = "Acres"
    planting_date: date
    growth_stage: GrowthStage = "Initial"
    season: Season = "Kharif"


class CropOut(BaseModel):
    id: int
    farm_id: int
    farm_name: str
    name: str
    variety: str
    area: float  # acres, as displayed in the app
    area_unit: str = "Acres"
    area_hectares: float
    planting_date: date
    growth_stage: str
    season: str
    days_since_planting: int


# ---------- irrigation ----------
class IrrigationLogIn(BaseModel):
    farm_id: int
    amount_liters: float | None = Field(default=None, gt=0)
    method: str = Field(default="Drip irrigation", max_length=50)


class ScheduleIn(BaseModel):
    farm_id: int
    scheduled_for: datetime
    amount_liters: float | None = Field(default=None, gt=0)
    method: str = Field(default="Drip irrigation", max_length=50)


class RecommendationIn(BaseModel):
    farm_id: int


# ---------- adviser ----------
class AdviserIn(BaseModel):
    message: str = Field(min_length=1, max_length=1000)
    farm_id: int | None = None
    include_irrigation_assessment: bool = False
