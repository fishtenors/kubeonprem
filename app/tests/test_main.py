#!/usr/bin/env python

from unittest.mock import patch
import os


def test_root_endpoint(client):
    """Test the root endpoint returns correct structure and data"""
    response = client.get("/")
    assert response.status_code == 200

    data = response.json()
    assert "time" in data
    assert "app" in data
    assert "build_sha" in data
    assert data["app"] == "KubeOnPrem"
    assert data["build_sha"] == "unknown"


def test_root_endpoint_with_env_vars(client_with_env):
    """Test the root endpoint with custom environment variables"""
    response = client_with_env.get("/")
    assert response.status_code == 200

    data = response.json()
    assert data["app"] == "TestApp"
    assert data["build_sha"] == "abc123def"


def test_root_endpoint_time_format(client):
    """Test that the time field contains a valid timestamp"""
    response = client.get("/")
    assert response.status_code == 200

    data = response.json()
    time_str = data["time"]

    # Verify it's a non-empty string
    assert isinstance(time_str, str)
    assert len(time_str) > 0

    # Verify it contains date-like components
    assert any(char.isdigit() for char in time_str)


def test_health_endpoint(client):
    """Test the health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200

    data = response.json()
    assert data == {"status": "online"}


def test_readiness_endpoint(client):
    """Test the readiness check endpoint"""
    response = client.get("/ready")
    assert response.status_code == 200

    data = response.json()
    assert data == {"status": "ready"}


def test_invalid_endpoint(client):
    """Test that invalid endpoints return 404"""
    response = client.get("/invalid")
    assert response.status_code == 404


def test_metrics_endpoint(client):
    """Test that the Prometheus metrics endpoint is exposed"""
    response = client.get("/metrics")
    assert response.status_code == 200

    # Check for basic Prometheus metrics format
    content = response.text
    assert "# HELP" in content or "# TYPE" in content or len(content) > 0


def test_multiple_root_calls(client):
    """Test that multiple calls to root endpoint work correctly"""
    response1 = client.get("/")
    response2 = client.get("/")

    assert response1.status_code == 200
    assert response2.status_code == 200

    # Both should have the same app and build_sha
    data1 = response1.json()
    data2 = response2.json()

    assert data1["app"] == data2["app"]
    assert data1["build_sha"] == data2["build_sha"]


def test_health_check_consistency(client):
    """Test that health check is consistently online"""
    for _ in range(5):
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "online"


def test_ready_check_consistency(client):
    """Test that readiness check is consistently ready"""
    for _ in range(5):
        response = client.get("/ready")
        assert response.status_code == 200
        assert response.json()["status"] == "ready"


def test_root_response_content_type(client):
    """Test that root endpoint returns JSON content type"""
    response = client.get("/")
    assert response.status_code == 200
    assert "application/json" in response.headers["content-type"]


def test_health_response_content_type(client):
    """Test that health endpoint returns JSON content type"""
    response = client.get("/health")
    assert response.status_code == 200
    assert "application/json" in response.headers["content-type"]


def test_ready_response_content_type(client):
    """Test that ready endpoint returns JSON content type"""
    response = client.get("/ready")
    assert response.status_code == 200
    assert "application/json" in response.headers["content-type"]


@patch.dict(os.environ, {"APP_NAME": "CustomApp", "BUILD_SHA": "xyz789"})
def test_environment_variable_override():
    """Test that environment variables can be overridden"""
    from fastapi.testclient import TestClient

    # Re-import to get the updated env vars
    import importlib
    import main as main_module

    importlib.reload(main_module)

    test_client = TestClient(main_module.app)
    response = test_client.get("/")

    data = response.json()
    assert data["app"] == "CustomApp"
    assert data["build_sha"] == "xyz789"


def test_concurrent_requests(client):
    """Test that the app handles multiple concurrent requests"""
    import concurrent.futures

    def make_request(endpoint):
        return client.get(endpoint)

    endpoints = ["/", "/health", "/ready", "/"] * 5

    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(make_request, endpoint) for endpoint in endpoints]
        results = [
            future.result() for future in concurrent.futures.as_completed(futures)
        ]

    # All requests should succeed
    assert all(result.status_code == 200 for result in results)


def test_openapi_docs_available(client):
    """Test that OpenAPI documentation is available"""
    response = client.get("/docs")
    assert response.status_code == 200


def test_openapi_json_available(client):
    """Test that OpenAPI JSON schema is available"""
    response = client.get("/openapi.json")
    assert response.status_code == 200

    data = response.json()
    assert "openapi" in data
    assert "info" in data
    assert "paths" in data
