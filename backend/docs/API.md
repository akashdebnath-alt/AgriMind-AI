# AgriMind AI API (v1)

Base URL: `http://<host>:8000/api/v1` (Android emulator: `http://10.0.2.2:8000/api/v1`).
Interactive docs: `/docs`. All endpoints except `/auth/register`, `/auth/login`, `/auth/forgot-password`
need `Authorization: Bearer <token>`.

| Flutter screen | Endpoints |
|---|---|
| LoginScreen | `POST /auth/register`, `POST /auth/login`, `POST /auth/forgot-password`, `GET /auth/me` |
| Dashboard | `GET /dashboard` (farm_count, total_area_acres, crop_count, irrigation_status) |
| Farms / Add / Details | `GET/POST /farms`, `GET/PUT/DELETE /farms/{id}` |
| Crops / Add Crop | `GET/POST /crops`, `GET/PUT/DELETE /crops/{id}` |
| Weather (+ dashboard card) | `GET /weather?farm_id=` |
| Irrigation | `GET /irrigation/overview`, `POST /irrigation/logs` (Mark as Irrigated), `POST /irrigation/schedule`, `GET /irrigation/logs`, `POST/GET /irrigation/recommendations` |
| Insights | `GET /insights` |
| AI Adviser | `GET /adviser/suggestions`, `POST /adviser/chat` |
| Profile | `GET/PATCH /profile`, `POST /auth/change-password` |

## Field mapping (Dart model -> JSON, snake_case)
- Farm: `name, location, area, area_unit ("Acres"|"Hectares"), soil_type`; response adds `id`, `area_hectares`, `area_acres`, `crop_count`.
  The Flutter `Farm` model needs an `id` field so edit/delete/crop-linking can use it.
- Crop: `name, variety, farm_id (or farm_name), area (acres by default), planting_date (YYYY-MM-DD), growth_stage, season`;
  response adds `id`, `farm_name`, `days_since_planting`. Stages: Initial, Development, Mid-season, Late-season, Harvest.
  Seasons: Kharif, Rabi, Zaid, Other.

## Behaviour notes
- Areas are stored in hectares (report design) and returned in the unit the user chose.
- Irrigation numbers are estimates: ETc = Kc x ET0, minus effective rainfall, 1 mm on 1 ha = 10,000 L.
  ET0/rain come from Open-Meteo using the farm location (geocoded on save). If weather is unavailable the
  response says `weather_source: "fallback"`, lists assumptions and lowers `confidence`; `/weather` returns 503.
- The AI Adviser is retrieval-only over a small curated knowledge base (no invented answers). It returns
  `grounded: false` when it has nothing relevant. An LLM/RAG layer can replace it later.
- Deleting a farm deletes its crops and irrigation records (matches the app's delete dialog).
- Differs from the report: multiple crops per farm are allowed (the app supports this), so `crops.farm_id` is not UNIQUE.
