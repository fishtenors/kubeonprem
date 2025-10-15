#!/usr/bin/env python

import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch
import sys
import os

# Add the parent directory to the Python path to allow importing main
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


@pytest.fixture
def client():
    """
    Fixture that provides a TestClient for the FastAPI app with default settings
    """
    from main import app

    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def client_with_env():
    """
    Fixture that provides a TestClient with custom environment variables
    """
    with patch.dict(os.environ, {"APP_NAME": "TestApp", "BUILD_SHA": "abc123def"}):
        # Need to reload the module to pick up new env vars
        import importlib
        import main as main_module

        importlib.reload(main_module)

        with TestClient(main_module.app) as test_client:
            yield test_client

        # Reload again to reset to original state
        importlib.reload(main_module)


@pytest.fixture
def mock_datetime():
    """
    Fixture that provides a mocked datetime for testing time-dependent behavior
    """
    with patch("main.datetime") as mock_dt:
        mock_dt.datetime.now.return_value = "2025-01-15 12:00:00"
        yield mock_dt


@pytest.fixture(scope="session")
def app_name():
    """
    Fixture that provides the default app name
    """
    return "KubeOnPrem"


@pytest.fixture(scope="session")
def build_sha_default():
    """
    Fixture that provides the default build SHA
    """
    return "unknown"
