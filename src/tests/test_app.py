import pytest

from app import app


@pytest.fixture()
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_index_returns_service_metadata(client):
    resp = client.get("/")
    assert resp.status_code == 200
    assert resp.get_json()["service"] == "sample-app"


def test_health(client):
    assert client.get("/health").status_code == 200


def test_ready(client):
    assert client.get("/ready").status_code == 200


@pytest.mark.integration
def test_metrics_endpoint(client):
    # Marked integration so the PR pipeline skips it and CI runs it.
    resp = client.get("/metrics")
    assert resp.status_code == 200
    assert b"app_requests_total" in resp.data
