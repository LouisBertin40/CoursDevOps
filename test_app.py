from app import alert_threshold, sanitize_input, app
from unittest.mock import patch
import redis

def test_alert_threshold():
    assert alert_threshold() == 25


def test_sanitize_input_escapes_html():
    assert sanitize_input("<script>") == "&lt;script&gt;"


def test_health_endpoint_success():
    client = app.test_client()
    with patch("app.get_redis_client") as mock_redis:
        mock_redis.return_value.ping.return_value = True
        response = client.get("/health")
        assert response.status_code == 200
        assert response.get_json()["status"] == "ok"


def test_health_endpoint_failure():
    client = app.test_client()
    with patch("app.get_redis_client") as mock_redis:
        mock_redis.return_value.ping.side_effect = redis.ConnectionError("Connexion impossible")
        response = client.get("/health")
        assert response.status_code == 503
        assert response.get_json()["status"] == "error"

def test_status_endpoint():
    client = app.test_client()
    response = client.get("/status")
    assert response.status_code == 200
    assert response.get_json()["service"] == "projet-devops-groupe-demo"
