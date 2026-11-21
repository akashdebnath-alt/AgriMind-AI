from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app import models  # noqa: F401  (register tables)
from app.core.config import settings
from app.db.session import Base, engine
from app.routers import (adviser, auth, crops, dashboard, farms, insights,
                         irrigation, profile, weather)


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(engine)
    yield


app = FastAPI(
    title=settings.app_name,
    description="Backend API for smart agriculture and irrigation management.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware, allow_origins=settings.cors_list, allow_methods=["*"], allow_headers=["*"],
)

for r in (auth, profile, farms, crops, weather, irrigation, insights, dashboard, adviser):
    app.include_router(r.router, prefix="/api/v1")


@app.get("/")
def home():
    return {"message": "Welcome to AgriMind AI Backend", "status": "running", "docs": "/docs"}


@app.get("/health")
def health_check():
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        database_status = "connected"
    except Exception as exc:
        database_status = "unavailable"
        return {
            "status": "unhealthy",
            "service": "AgriMind AI",
            "database": database_status,
            "error": str(exc),
        }

    return {
        "status": "healthy",
        "service": "AgriMind AI",
        "database": database_status,
    }
