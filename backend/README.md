# AgriMind AI - Backend

FastAPI and SQLAlchemy REST API for the Flutter client. SQLite is used for local development and MySQL 8 is available through Docker.

## Features

- JWT authentication and profile management
- Per-user farm and crop CRUD operations
- Area conversion between acres and hectares
- Open-Meteo weather and geocoding
- Irrigation planning and logs
- ETc calculations (`ETc = Kc x ET0`)
- Dashboard and insight aggregates
- Grounded retrieval-based AI adviser
- Deterministic virtual soil/weather readings and a crop-aware, synthetic-data Random Forest irrigation assessment, integrated with the AI Adviser

## Quick start on Windows

From the project root:

```powershell
.\backend\run-server.ps1
```

The script creates `.env` when it does not exist, uses SQLite, creates `agrimind_dev.db`, and starts uvicorn on port `8000`.

Open:

- Swagger UI: <http://127.0.0.1:8000/docs>
- ReDoc: <http://127.0.0.1:8000/redoc>
- Health check: <http://127.0.0.1:8000/health>

## Manual setup

```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\Activate.ps1
py -m pip install -r requirements-dev.txt
Copy-Item .env.example .env
py -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

For SQLite, `.env` should contain:

```dotenv
DATABASE_URL=sqlite:///./agrimind_dev.db
SECRET_KEY=replace-with-a-long-random-local-string
ACCESS_TOKEN_EXPIRE_MINUTES=10080
CORS_ORIGINS=*
TIMEZONE=Asia/Kolkata
```

## Run with MySQL and Docker

```powershell
cd backend
Copy-Item .env.example .env
docker compose up --build
```

Docker Compose starts MySQL 8 and the FastAPI service. The database is initialized from `database_schema.sql`, and SQLAlchemy creates missing tables at startup.

## Tests

```powershell
cd backend
py -m pip install -r requirements-dev.txt
py -m pytest -q
```

The tests use an isolated in-memory SQLite database and mocked weather responses.

## Layout

- `app/main.py` - application setup and router registration
- `app/routers/` - HTTP endpoints
- `app/database_models.py` - SQLAlchemy models
- `app/api_schemas.py` - request and response validation
- `app/services/` - weather, agronomy, irrigation, and adviser logic
- `app/db/session.py` - database engine and sessions
- `database_schema.sql` - reference MySQL DDL
- `docs/API.md` - Flutter endpoint contract

Set a strong random `SECRET_KEY` before deploying. See [docs/API.md](docs/API.md) for the complete endpoint contract.

The irrigation assessment uses a synthetic training dataset and simulated sensor values for demonstration.
It is not a substitute for field measurements or local agronomic advice. To regenerate the dataset, train
the model, and write hold-out metrics, run `py -m app.services.train_irrigation_model` from `backend`.
