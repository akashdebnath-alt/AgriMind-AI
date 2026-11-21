# AgriMind AI

AgriMind AI is a cross-platform agricultural water-management application built with Flutter and FastAPI. It combines farm and crop management, live weather data, scientific irrigation calculations, dashboard insights, and a grounded agricultural adviser.

## Features

- Account registration, login, password changes, and profile settings
- Farm and crop CRUD operations with per-user data isolation
- Acres/hectares conversion and soil information
- Open-Meteo weather forecasts, humidity, rainfall, temperature, and ET0 estimates
- Irrigation schedules, irrigation history, and saved recommendations
- Evapotranspiration calculation using `ETc = Kc x ET0`
- Dashboard summaries and crop distribution insights
- Retrieval-based agricultural chat with source grounding
- SQLite local development and MySQL/Docker deployment

## Architecture

```text
Flutter application
        |
        | REST / JSON / Bearer JWT
        v
FastAPI backend (/api/v1)
        |
        +-- SQLAlchemy
        |       |
        |       +-- SQLite for local development
        |       +-- MySQL for Docker/production
        |
        +-- Open-Meteo geocoding and weather APIs
```

## Technology Stack

- **Frontend:** Flutter, Material 3, Dart
- **Backend:** Python, FastAPI, SQLAlchemy
- **Authentication:** JWT bearer tokens and password hashing
- **Databases:** SQLite and MySQL 8
- **Weather:** Open-Meteo geocoding and forecast APIs
- **Testing:** pytest and FastAPI TestClient

## Project Layout

```text
lib/                 Flutter application
backend/app/         FastAPI application
backend/tests/       Backend API tests
backend/docs/API.md  Endpoint contract
backend/database_schema.sql
                     Reference MySQL schema
```

## Prerequisites

- Flutter SDK
- Python 3.11 or newer
- Windows PowerShell for the provided local startup script
- Docker Desktop only for the MySQL/Docker setup

## Quick Start

### 1. Start the backend

From the project root on Windows:

```powershell
.\backend\run-server.ps1
```

The script creates `backend/.env` if needed, uses SQLite by default, creates `backend/agrimind_dev.db`, and starts:

- API: <http://127.0.0.1:8000>
- Swagger docs: <http://127.0.0.1:8000/docs>

Manual startup:

```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\Activate.ps1
py -m pip install -r requirements-dev.txt
Copy-Item .env.example .env
py -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

For manual SQLite setup, set `DATABASE_URL` to `sqlite:///./agrimind_dev.db` in `backend/.env`.

### 2. Start Flutter

```powershell
flutter pub get
flutter run
```

The Flutter API configuration uses:

- Android emulator: `http://10.0.2.2:8000/api/v1`
- Web, Windows, Linux, and macOS: `http://127.0.0.1:8000/api/v1`

For a physical Android device, replace the URL in `lib/core/constants/api_constants.dart` with your computer's LAN IP and ensure the backend listens on `0.0.0.0`.

## Docker and MySQL

```powershell
cd backend
Copy-Item .env.example .env
docker compose up --build
```

The Compose configuration starts MySQL 8 on port `3306` and the API on port `8000`.

## Tests

Run the backend tests:

```powershell
cd backend
py -m pytest -q
```

Run Flutter analysis:

```powershell
flutter analyze
```

## API

The API is available under `/api/v1`. Authentication endpoints are public; all remaining endpoints require `Authorization: Bearer <token>`.

See [backend/docs/API.md](backend/docs/API.md) for endpoint and response details.

## Configuration

Important settings in `backend/.env`:

| Setting | Purpose | Default |
|---|---|---|
| `DATABASE_URL` | SQLAlchemy database connection | SQLite dev database |
| `SECRET_KEY` | JWT signing key | Development-only fallback |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Login-session duration | `10080` |
| `CORS_ORIGINS` | Allowed browser origins | `*` |
| `TIMEZONE` | Application timezone | `Asia/Kolkata` |

Set a strong, unique `SECRET_KEY` before deploying.
