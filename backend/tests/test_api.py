import csv
from datetime import date, timedelta

import pytest

from tests.conftest import auth_headers

B = "/api/v1"


def make_farm(client, h, **over):
    body = {"name": "Green Valley", "location": "Guwahati, Assam", "area": 2, "area_unit": "Hectares",
            "soil_type": "Loamy", **over}
    r = client.post(f"{B}/farms", json=body, headers=h)
    assert r.status_code == 201, r.text
    return r.json()


def test_auth_flow(client):
    h = auth_headers(client)
    assert client.get(f"{B}/auth/me", headers=h).json()["email"] == "farmer@example.com"
    assert client.post(f"{B}/auth/login", json={"email": "farmer@example.com", "password": "bad"}).status_code == 401
    assert client.post(f"{B}/auth/login", json={"email": "FARMER@example.com", "password": "password123"}).status_code == 200
    assert client.get(f"{B}/farms").status_code == 401


def test_farm_crud_and_units(client):
    h = auth_headers(client)
    farm = make_farm(client, h, area=2.5, area_unit="Acres")
    assert farm["area"] == 2.5 and abs(farm["area_hectares"] - 1.0117) < 0.001
    upd = client.put(f"{B}/farms/{farm['id']}", json={"name": "GV", "location": "Guwahati", "area": 1,
                                                       "area_unit": "Hectares", "soil_type": "Clay"}, headers=h)
    assert upd.json()["area"] == 1.0 and upd.json()["area_unit"] == "Hectares"
    assert client.post(f"{B}/farms", json={"name": "x", "location": "y", "area": 0}, headers=h).status_code == 422
    assert client.delete(f"{B}/farms/{farm['id']}", headers=h).status_code == 204
    assert client.get(f"{B}/farms", headers=h).json() == []


def test_ownership_isolated(client):
    a, b = auth_headers(client, "a@x.com"), auth_headers(client, "b@x.com")
    farm = make_farm(client, a)
    assert client.get(f"{B}/farms/{farm['id']}", headers=b).status_code == 404
    assert client.get(f"{B}/farms", headers=b).json() == []


def test_crops_and_cascade(client):
    h = auth_headers(client)
    farm = make_farm(client, h)
    crop = {"farm_name": "Green Valley", "name": "Rice", "area": 1, "planting_date": str(date.today() - timedelta(days=10)),
            "growth_stage": "Development", "season": "Kharif"}
    r = client.post(f"{B}/crops", json=crop, headers=h)
    assert r.status_code == 201 and r.json()["days_since_planting"] >= 9
    future = {**crop, "planting_date": str(date.today() + timedelta(days=5))}
    assert client.post(f"{B}/crops", json=future, headers=h).status_code == 422
    client.delete(f"{B}/farms/{farm['id']}", headers=h)
    assert client.get(f"{B}/crops", headers=h).json() == []


def test_recommendation_math(client):
    h = auth_headers(client)
    farm = make_farm(client, h)  # 2 ha
    client.post(f"{B}/crops", headers=h, json={
        "farm_id": farm["id"], "name": "Tomato", "area": 2, "area_unit": "Hectares",
        "planting_date": str(date.today() - timedelta(days=40)), "growth_stage": "Mid-season"})
    r = client.post(f"{B}/irrigation/recommendations", json={"farm_id": farm["id"]}, headers=h)
    assert r.status_code == 201
    plan = r.json()
    # Kc 1.15 x ET0 5.0 = 5.75 mm; 5.75 mm x 2 ha x 10,000 L = 115,000 L
    assert plan["daily_liters"] == 115000 and plan["confidence"] == "high"
    assert plan["weekly_liters"] == 115000 * 7
    hist = client.get(f"{B}/irrigation/recommendations", params={"farm_id": farm["id"]}, headers=h).json()
    assert len(hist) == 1


def test_irrigation_log_overview_insights(client):
    h = auth_headers(client)
    farm = make_farm(client, h)
    client.post(f"{B}/crops", headers=h, json={
        "farm_id": farm["id"], "name": "Rice", "area": 1, "area_unit": "Hectares",
        "planting_date": str(date.today() - timedelta(days=20)), "growth_stage": "Development"})
    assert client.get(f"{B}/irrigation/overview", headers=h).json()["status"] == "Needs Monitoring"
    r = client.post(f"{B}/irrigation/logs", json={"farm_id": farm["id"], "amount_liters": 450}, headers=h)
    assert r.status_code == 201 and r.json()["date_label"] == "Today"
    ov = client.get(f"{B}/irrigation/overview", headers=h).json()
    assert ov["status"] == "Completed Today" and ov["history"][0]["amount_liters"] == 450
    ins = client.get(f"{B}/insights", headers=h).json()
    assert ins["overview"]["water_used_liters"] == 450 and ins["overview"]["active_crops"] == 1
    assert ins["crop_distribution"][0]["name"] == "Rice"
    assert client.get(f"{B}/dashboard", headers=h).json()["irrigation_status"] == "Completed"


def test_weather_and_adviser(client):
    h = auth_headers(client)
    assert client.get(f"{B}/weather", headers=h).status_code == 404
    make_farm(client, h)
    w = client.get(f"{B}/weather", headers=h).json()
    assert len(w["forecast"]) == 5 and w["current"]["humidity_pct"] == 72
    a = client.post(f"{B}/adviser/chat", json={"message": "Why are my leaves turning yellow?"}, headers=h).json()
    assert a["grounded"] and a["sources"][0]["id"] == "yellow-leaves"
    miss = client.post(f"{B}/adviser/chat", json={"message": "Who won the cricket match?"}, headers=h).json()
    assert miss["grounded"] is False


def test_virtual_sensor_ml_llm_rag_pipeline(client, monkeypatch):
    from app.routers import adviser

    h = auth_headers(client)
    farm = make_farm(client, h)
    client.post(f"{B}/crops", headers=h, json={
        "farm_id": farm["id"], "name": "Tomato", "area": 1, "area_unit": "Hectares",
        "planting_date": str(date.today() - timedelta(days=40)), "growth_stage": "Mid-season"})

    captured = {}
    source = {"id": "irrigation-frequency", "title": "How often to irrigate", "text": "Check soil moisture."}

    def fake_search(query, **_kwargs):
        captured["rag_query"] = query
        return [source]

    monkeypatch.setattr(adviser.rag, "search", fake_search)
    monkeypatch.setattr(adviser, "llm_enabled", lambda: True)

    def fake_gemini(_system_prompt, user_prompt, **_kwargs):
        captured["system_prompt"] = _system_prompt
        captured["prompt"] = user_prompt
        return "Check the soil before irrigating today."

    monkeypatch.setattr(adviser, "ask_gemini", fake_gemini)
    response = client.post(f"{B}/adviser/chat", headers=h, json={
        "message": "Give me irrigation advice", "farm_id": farm["id"],
        "include_irrigation_assessment": True})

    assert response.status_code == 200, response.text
    result = response.json()
    assessment = result["irrigation_assessment"]
    sensor = assessment["virtual_sensor"]
    readings = assessment["virtual_sensor"]["readings"]
    assert sensor["mode"] == "simulated" and sensor["simulated"] is True
    assert sensor["sensor_type"] == "virtual" and sensor["farm_id"] == farm["id"]
    assert set(readings) == {
        "soil_moisture_pct", "air_temperature_c", "humidity_pct",
        "soil_temperature_c", "rainfall_mm", "et0_mm",
    }
    assert 0 <= readings["soil_moisture_pct"] <= 100
    assert 0 <= readings["humidity_pct"] <= 100
    assert -10 <= readings["air_temperature_c"] <= 60
    assert -10 <= readings["soil_temperature_c"] <= 60
    assert 0 <= readings["rainfall_mm"] <= 300
    assert 0 <= readings["et0_mm"] <= 20
    assert sensor["farm_context"]["crop_type"] == "vegetable"
    assert sensor["farm_context"]["growth_stage"] == "Mid-season"
    assert sensor["farm_context"]["soil_type"] == "loamy"
    assert sensor["farm_context"]["crop_area_hectares"] == 1
    assert isinstance(assessment["ml_prediction"]["irrigation_needed"], bool)
    assert 0 <= assessment["ml_prediction"]["probability"] <= 1
    assert 0 <= assessment["ml_prediction"]["confidence"] <= 1
    assert assessment["ml_prediction"]["training_data"] == "synthetic"
    assert result["mode"] == "gemini" and result["sources"][0]["id"] == source["id"]
    assert "Random Forest predicts" in captured["prompt"]
    assert "not physical sensor measurements" in captured["prompt"]
    assert "Crop: Tomato" in captured["prompt"] and "area 1.00 hectares" in captured["prompt"]
    assert "ET0" in captured["prompt"] and "irrigation timing" in captured["rag_query"]
    assert "heat stress" in captured["rag_query"]
    assert "state both clearly" in captured["system_prompt"]
    assert "does not make a yes/no timing decision" in captured["prompt"]

    repeated = client.post(f"{B}/adviser/chat", headers=h, json={
        "message": "Give me irrigation advice", "farm_id": farm["id"],
        "include_irrigation_assessment": True})
    assert repeated.json()["irrigation_assessment"]["virtual_sensor"]["readings"] == readings


def test_adviser_existing_plan_matches_irrigation_overview(client, monkeypatch):
    from app.routers import adviser
    from app.services import rag

    monkeypatch.setattr(rag, "semantic_scores", lambda query, timeout=3.0: {})
    monkeypatch.setattr(adviser, "llm_enabled", lambda: False)
    h = auth_headers(client)
    farm = make_farm(client, h)
    client.post(f"{B}/crops", headers=h, json={
        "farm_id": farm["id"], "name": "Tomato", "area": 1,
        "area_unit": "Hectares", "planting_date": str(date.today()),
        "growth_stage": "Mid-season",
    })

    overview = client.get(f"{B}/irrigation/overview", headers=h).json()
    response = client.post(f"{B}/adviser/chat", headers=h, json={
        "message": "Assess irrigation", "farm_id": farm["id"],
        "include_irrigation_assessment": True,
    }).json()
    existing = response["irrigation_assessment"]["existing_plan"]

    assert existing["daily_liters"] == overview["daily_estimate_liters"]
    assert existing["weekly_liters"] == overview["weekly_estimate_liters"]


def test_irrigation_model_handles_dry_and_wet_conditions():
    from app.services.irrigation_ml import predict_irrigation

    context = {
        "crop_type": "vegetable", "growth_stage": "Mid-season", "soil_type": "loamy",
    }
    dry = predict_irrigation({
        "soil_moisture_pct": 15, "air_temperature_c": 40, "humidity_pct": 30,
        "soil_temperature_c": 32, "rainfall_mm": 0, "et0_mm": 8,
    }, context)
    wet = predict_irrigation({
        "soil_moisture_pct": 85, "air_temperature_c": 20, "humidity_pct": 90,
        "soil_temperature_c": 18, "rainfall_mm": 20, "et0_mm": 2,
    }, context)
    assert dry["irrigation_needed"] is True
    assert wet["irrigation_needed"] is False
    with pytest.raises(ValueError, match="between 0.0 and 100.0"):
        predict_irrigation({
            "soil_moisture_pct": 101, "air_temperature_c": 20, "humidity_pct": 90,
            "soil_temperature_c": 18, "rainfall_mm": 0, "et0_mm": 2,
        }, context)


def test_synthetic_dataset_training_report(tmp_path):
    from app.services.irrigation_ml import FEATURES
    from app.services.train_irrigation_model import generate_dataset, train_and_evaluate

    dataset_path = tmp_path / "irrigation.csv"
    model_path = tmp_path / "irrigation.joblib"
    metrics_path = tmp_path / "metrics.json"
    generate_dataset(dataset_path, samples=500)
    with dataset_path.open(newline="", encoding="utf-8") as dataset:
        rows = list(csv.DictReader(dataset))

    assert len(rows) == 500
    assert set(rows[0]) == {*FEATURES, "irrigation_needed"}
    assert all(row["irrigation_needed"] in {"0", "1"} for row in rows)
    metrics = train_and_evaluate(dataset_path, model_path, metrics_path)
    assert metrics["test_samples"] == 100
    assert len(metrics["confusion_matrix"]["matrix"]) == 2
    assert metrics["sample_prediction"]["irrigation_needed"] in (True, False)
    assert model_path.is_file() and metrics_path.is_file()


def test_assessment_uses_weather_fallback_without_crops(client, monkeypatch):
    from app.routers import adviser
    from app.services import rag, weather

    monkeypatch.setattr(weather, "forecast_for_farm", lambda farm, db: None)
    monkeypatch.setattr(rag, "semantic_scores", lambda query, timeout=3.0: {})
    monkeypatch.setattr(adviser, "llm_enabled", lambda: False)
    h = auth_headers(client)
    farm = make_farm(client, h)

    response = client.post(f"{B}/adviser/chat", headers=h, json={
        "message": "Give me irrigation advice", "farm_id": farm["id"],
        "include_irrigation_assessment": True})

    assert response.status_code == 200, response.text
    result = response.json()
    sensor = result["irrigation_assessment"]["virtual_sensor"]
    assert sensor["sources"]["weather"] == "configured_fallback"
    assert sensor["farm_context"]["crop_type"] == "none"
    assert sensor["farm_context"]["crop_area_hectares"] == 0
    assert sensor["readings"]["rainfall_mm"] == 0
    assert sensor["readings"]["et0_mm"] > 0
    assert result["irrigation_assessment"]["ml_prediction"]["irrigation_needed"] in (True, False)
    assert result["irrigation_assessment"]["decision_disagreement"] is None
    assert result["irrigation_assessment"]["existing_plan"]["decision_source"] == "daily_demand_estimate"
    assert any(source["id"] == "irrigation-frequency" for source in result["sources"])
    assert result["mode"] == "retrieval"


def test_irrigation_assessment_requires_owned_farm(client):
    h = auth_headers(client)
    missing_farm = client.post(f"{B}/adviser/chat", headers=h, json={
        "message": "Assess irrigation", "include_irrigation_assessment": True})
    assert missing_farm.status_code == 422

    other_user = auth_headers(client, "other@example.com")
    farm = make_farm(client, h)
    forbidden = client.post(f"{B}/adviser/chat", headers=other_user, json={
        "message": "Assess irrigation", "farm_id": farm["id"],
        "include_irrigation_assessment": True})
    assert forbidden.status_code == 404


def test_profile_update(client):
    h = auth_headers(client)
    r = client.patch(f"{B}/profile", json={"language": "Bengali", "weather_alerts_enabled": False}, headers=h)
    assert r.json()["language"] == "Bengali" and r.json()["weather_alerts_enabled"] is False
    assert client.patch(f"{B}/profile", json={"language": "French"}, headers=h).status_code == 422
