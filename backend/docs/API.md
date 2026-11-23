# AgriMind AI API (v1)

Base URL: `http://<host>:8000/api/v1` (Android emulator: `http://10.0.2.2:8000/api/v1`).
Interactive docs: `/docs`. All endpoints except `/auth/register`, `/auth/login`, `/auth/forgot-password`
need `Authorization: Bearer <token>`.

Local setup uses SQLite. Docker setup uses MySQL 8. API startup creates missing SQLAlchemy tables automatically.

| Flutter screen | Endpoints |
|---|---|
| LoginScreen | `POST /auth/register`, `POST /auth/login`, `POST /auth/forgot-password`, `GET /auth/me` |
| Dashboard | `GET /dashboard` (farm_count, total_area_acres, crop_count, irrigation_status) |
| Farms / Add / Details | `GET/POST /farms`, `GET/PUT/DELETE /farms/{id}` |
| Crops / Add Crop | `GET/POST /crops`, `GET/PUT/DELETE /crops/{id}` |
| Weather (+ dashboard card) | `GET /weather?farm_id=` |
| Irrigation | `GET /irrigation/overview`, `POST /irrigation/logs` (Mark as Irrigated), `POST /irrigation/schedule`, `GET /irrigation/logs`, `POST/GET /irrigation/recommendations`, `POST /adviser/chat` with `include_irrigation_assessment: true` |
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
- The AI Adviser retrieves relevant curated knowledge and uses Gemini when configured; it returns a
  retrieval-only answer when Gemini is unavailable.
- For a farm-specific irrigation assessment, send `POST /adviser/chat` with `message`, `farm_id`, and
  `include_irrigation_assessment: true`. The response adds `irrigation_assessment.virtual_sensor`,
  `irrigation_assessment.ml_prediction`, and the existing irrigation estimate. Sensor values are
  deterministic daily simulations derived from farm/weather estimates, not physical measurements. Readings
  include soil moisture, air and soil temperature, humidity, rainfall, and ET0, plus crop/stage/soil context.
  The Random Forest uses those features and was trained on synthetic data; `probability` is the model's
  irrigation-class probability, while `confidence` is the larger of the two class probabilities. Neither is
  real-world accuracy, and the result is advisory only.
- `irrigation_assessment.existing_plan` includes the current ETc water-demand estimate. Its
  `irrigation_recommended` value and the top-level `decision_disagreement` are only populated when the plan
  provides a yes/no root-zone water-balance decision. For the ETc baseline, they are `null`: positive daily
  water demand is not by itself a decision to irrigate today.
- The Adviser sends the simulated readings, model result, farm/crop details, and retrieved knowledge notes
  to Gemini when configured. Without Gemini it returns the same assessment alongside the existing retrieval
  answer. Missing weather uses configured fallbacks and is identified in `virtual_sensor.sources`.
- Retrain and evaluate the model from the backend directory with
  `python -m app.services.train_irrigation_model`. This regenerates
  `app/data/irrigation_synthetic_dataset.csv`, `app/data/irrigation_rf.joblib`, and
  `app/data/irrigation_model_metrics.json` (scikit-learn 1.9.1). The evaluation is a hold-out split from the same
  synthetic-label process and does not establish real-world accuracy.
- Deleting a farm deletes its crops and irrigation records (matches the app's delete dialog).
- Differs from the report: multiple crops per farm are allowed (the app supports this), so `crops.farm_id` is not UNIQUE.
