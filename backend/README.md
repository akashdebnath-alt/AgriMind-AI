# AgriMind AI - Backend

FastAPI + SQLAlchemy backend for the Flutter app. MySQL 8 in production, SQLite for quick local runs.

## Run locally
```
cd backend
python -m venv .venv && source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt
cp .env.example .env                                   # remove DATABASE_URL line to use SQLite
uvicorn app.main:app --reload
```
Open http://localhost:8000/docs. Tests: `pytest`.

## Run with MySQL (Docker)
```
cp .env.example .env && docker compose up --build
```

## Layout
- `app/routers/` HTTP endpoints - `app/services/` weather, agronomy (ETc = Kc x ET0), engine, knowledge base
- `app/models.py` tables - `app/schemas.py` validation - `schema.sql` reference DDL - `docs/API.md` contract

Set a long random `SECRET_KEY` before deploying. See `docs/API.md` for the Flutter endpoint mapping.
