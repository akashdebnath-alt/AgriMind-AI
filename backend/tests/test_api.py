from datetime import date, timedelta

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


def test_profile_update(client):
    h = auth_headers(client)
    r = client.patch(f"{B}/profile", json={"language": "Bengali", "weather_alerts_enabled": False}, headers=h)
    assert r.json()["language"] == "Bengali" and r.json()["weather_alerts_enabled"] is False
    assert client.patch(f"{B}/profile", json={"language": "French"}, headers=h).status_code == 422
