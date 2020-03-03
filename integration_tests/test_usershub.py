import json

import requests

import pytest
from http_client import usershub_client as unlogged_client
from integration_tests_conf import GEONATURE_CONFIG


@pytest.fixture
def client(unlogged_client):
    unlogged_client.login()
    yield unlogged_client


def test_home(unlogged_client):
    response = unlogged_client.get("/")
    assert response.status_code == 200
    assert "Identifiant" in response.text
    assert "Mot de passe" in response.text


def test_login(unlogged_client):
    assert unlogged_client.login().status_code == 200


def test_all_pages(client):
    urls = [
        ("/users/list", "Utilisateurs"),
        ("/organisms/list", "Groupes"),
        ("/groups/list", "Listes"),
        ("/lists/list", "Applications"),
        ("/applications/list", "Profils"),
        ("/temp_users/list", "Demandes de compte en cours"),
    ]
    for (url, title) in urls:
        response = client.get(url)
        assert response.status_code == 200
        text = response.text
        assert "table" in text
        assert title in text


def test_static_files(client):
    assert client.check_status("/static/node_modules/jquery/dist/jquery.min.js", 200)
    assert client.check_status("/constants.js", 200)


def test_create_user(client):
    response = client.post(
        "/api_register/create_temp_user",
        json={
            "identifiant": "integration_test_user",
            "password": "integration_test_password",
            "password_confirmation": "integration_test_password",
            "email": "fake@integrationtest.com",
            "nom_role": "integration_test_name",
            "prenom_role": "integration_test_last_name",
            "remarques": "",
            "organisme": "",
            "groupe": False,
            "id_application": GEONATURE_CONFIG.application_id,
            "id_organisme": client.conf.root_org_id,
        },
    )
    assert response.status_code == 200
    token = response.json().get("token")
    assert token

    response = client.post(
        "/api_register/valid_temp_user",
        json={"token": token, "id_application": GEONATURE_CONFIG.application_id,},
    )

    user = response.json()
    email = user.get("email")
    assert email == "fake@integrationtest.com"
    id_role = user.get("id_role")
    assert isinstance(id_role, int)

    response = client.get("/user/info/%s" % id_role)

    name = user.get("prenom_role", "")
    last_name = user.get("nom_role", "")
    assert (last_name + " " + name) in response.text

    response = client.get("/users/delete/%s" % id_role)
    assert response.status_code == 200

    # we can't check for a 404 because the URL with a bad
    # id raises a 500
    response = client.get("/user/info/%s" % id_role)
    assert response.status_code != 200
