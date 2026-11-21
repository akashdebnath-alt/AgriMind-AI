import os

os.environ["DATABASE_URL"] = "sqlite://"

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.session import Base, get_db
from app.main import app
from app.services import weather

FAKE = {
    "current": {"temperature_c": 28, "feels_like_c": 30, "humidity_pct": 72, "wind_kmh": 8,
                "cloud_cover_pct": 35, "rainfall_mm": 0, "condition": "Partly cloudy"},
    "daily": [{"date": f"2026-11-{21 + i}", "condition": "Clear sky", "t_max": 32, "t_min": 24,
               "rain_mm": 0.0, "et0_mm": 5.0} for i in range(7)],
}


@pytest.fixture()
def client(monkeypatch):
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine, autoflush=False, autocommit=False)

    def override():
        db = Session()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override
    monkeypatch.setattr(weather, "get_forecast", lambda lat, lon: FAKE)
    monkeypatch.setattr(weather, "geocode", lambda name: (26.14, 91.73))
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


def auth_headers(client, email="farmer@example.com"):
    r = client.post("/api/v1/auth/register", json={"email": email, "password": "password123"})
    assert r.status_code == 201, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}
