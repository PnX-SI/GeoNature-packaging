import json

import requests

import pytest
from http_client import geonature_client as unlogged_client

@pytest.fixture
def client(unlogged_client):
    unlogged_client.login()
    yield unlogged_client


def test_home(unlogged_client):
    response = unlogged_client.get("/")
    assert response.status_code == 200


def test_api(client):
    response = client.get("api/gn_commons/modules")
    assert response.status_code == 200

