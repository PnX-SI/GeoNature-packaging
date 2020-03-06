import json

import requests
from bs4 import BeautifulSoup

import pytest
from http_client import geonature_client as unlogged_client


@pytest.fixture
def client(unlogged_client):
    unlogged_client.login()
    yield unlogged_client


@pytest.fixture(scope="module", autouse=True)
def test_ping():
    next(unlogged_client.__wrapped__()).ping_or_die()


def test_home(unlogged_client):
    response = unlogged_client.get("/")
    assert response.status_code == 200


def test_page(client):
    response = client.get("/")
    assert response.status_code == 200
    text = response.text
    soup = BeautifulSoup(text, "html.parser")
    assert soup.title.string == "GeoNature"

    for index, item in enumerate(soup.find_all("script")):
        if index > 5:
            break
        src = item.get("src")
        assert client.check_status(src, 200)


def test_api(client):
    urls = ["api/gn_commons/modules", "api/occtax/releves?limit=12", "api/users/menu/1"]
    for url in urls:
        assert client.check_status(url, 200)
