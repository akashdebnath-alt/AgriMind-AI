from datetime import date, datetime

from sqlalchemy import (BigInteger, Boolean, Date, DateTime, Float, ForeignKey,
                        Integer, Numeric, String, Text, func)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base

BigId = BigInteger().with_variant(Integer, "sqlite")


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(BigId, primary_key=True, autoincrement=True)
    email: Mapped[str] = mapped_column(String(190), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    full_name: Mapped[str | None] = mapped_column(String(100))
    language: Mapped[str] = mapped_column(String(20), default="English")
    notifications_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    weather_alerts_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    farms: Mapped[list["Farm"]] = relationship(back_populates="user", cascade="all, delete-orphan")


class Farm(Base):
    __tablename__ = "farms"

    id: Mapped[int] = mapped_column(BigId, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigId, ForeignKey("users.id", onupdate="CASCADE"), index=True)
    farm_name: Mapped[str] = mapped_column(String(100))
    location: Mapped[str] = mapped_column(String(150))
    area_hectares: Mapped[float] = mapped_column(Numeric(12, 4))  # canonical unit
    area_unit: Mapped[str] = mapped_column(String(10), default="Acres")  # unit the user entered / sees
    soil_type: Mapped[str | None] = mapped_column(String(50))
    latitude: Mapped[float | None] = mapped_column(Float)
    longitude: Mapped[float | None] = mapped_column(Float)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user: Mapped[User] = relationship(back_populates="farms")
    crops: Mapped[list["Crop"]] = relationship(back_populates="farm", cascade="all, delete-orphan")
    logs: Mapped[list["IrrigationLog"]] = relationship(back_populates="farm", cascade="all, delete-orphan")
    predictions: Mapped[list["IrrigationPrediction"]] = relationship(
        back_populates="farm", cascade="all, delete-orphan"
    )


class Crop(Base):
    __tablename__ = "crops"

    id: Mapped[int] = mapped_column(BigId, primary_key=True, autoincrement=True)
    farm_id: Mapped[int] = mapped_column(BigId, ForeignKey("farms.id", onupdate="CASCADE"), index=True)
    crop_name: Mapped[str] = mapped_column(String(100))
    variety: Mapped[str] = mapped_column(String(100), default="Not specified")
    area_hectares: Mapped[float] = mapped_column(Numeric(12, 4))
    planting_date: Mapped[date] = mapped_column(Date)
    growth_stage: Mapped[str] = mapped_column(String(30), default="Initial")
    season: Mapped[str] = mapped_column(String(20), default="Kharif")
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    farm: Mapped[Farm] = relationship(back_populates="crops")


class IrrigationLog(Base):
    """Completed irrigation events and scheduled ones (status = completed | scheduled)."""

    __tablename__ = "irrigation_logs"

    id: Mapped[int] = mapped_column(BigId, primary_key=True, autoincrement=True)
    farm_id: Mapped[int] = mapped_column(BigId, ForeignKey("farms.id", onupdate="CASCADE"), index=True)
    amount_liters: Mapped[float | None] = mapped_column(Float)
    method: Mapped[str] = mapped_column(String(50), default="Drip irrigation")
    status: Mapped[str] = mapped_column(String(15), default="completed")
    occurred_at: Mapped[datetime | None] = mapped_column(DateTime)
    scheduled_for: Mapped[datetime | None] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    farm: Mapped[Farm] = relationship(back_populates="logs")


class IrrigationPrediction(Base):
    __tablename__ = "irrigation_predictions"

    id: Mapped[int] = mapped_column(BigId, primary_key=True, autoincrement=True)
    farm_id: Mapped[int] = mapped_column(BigId, ForeignKey("farms.id", onupdate="CASCADE"), index=True)
    prediction_date: Mapped[date] = mapped_column(Date)
    irrigation_mm: Mapped[float] = mapped_column(Float)
    volume_liters: Mapped[float] = mapped_column(Float)
    confidence: Mapped[str] = mapped_column(String(10))
    recommendation: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    farm: Mapped[Farm] = relationship(back_populates="predictions")
