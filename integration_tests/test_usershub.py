import json

import requests

import pytest
from http_client import usershub_client as unlogged_client
from integration_tests_conf import GEONATURE_CONFIG


@pytest.fixture
def client(unlogged_client):
    ''' 
    Enables to process test as a logged client
    '''
    unlogged_client.login()
    yield unlogged_client


@pytest.fixture(scope="module", autouse=True)
def test_ping():
    '''
    Try to process a ping on the aplication url. In case of failure, aborts the test process
    '''    
    next(unlogged_client.__wrapped__()).ping_or_die()


def test_home(unlogged_client):
    '''
        Asserts if home page '/' return a success code 200 and checks page content
    '''
    response = unlogged_client.get("/")
    assert response.status_code == 200
    assert "Identifiant" in response.text
    assert "Mot de passe" in response.text


def test_login(unlogged_client):
    '''
        Asserts if login process is sucessful
    '''
    assert unlogged_client.login().status_code == 200


def test_all_pages(client):
    '''
    For all pages of USERSHUB: checks if the page can be reached and if it has specified content
    
    Args:
        client : pytest fixture to process the test as a connected client 
    '''
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
    '''
        Checks if some static files can be reached
    '''
    assert client.check_status("/static/node_modules/jquery/dist/jquery.min.js", 200)
    assert client.check_status("/constants.js", 200)


def test_create_user(client):
    '''
        Process the whole user cretation / delete cycle and checks the process is successful
    '''

    # temp user creation
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

    # get the token
    token = response.json().get("token")
    assert token

    # temp user validation / user creation
    response = client.post(
        "/api_register/valid_temp_user",
        json={"token": token, "id_application": GEONATURE_CONFIG.application_id,},
    )

    user = response.json()

    # checks email
    email = user.get("email")
    assert email == "fake@integrationtest.com"

    # checks id_role is integer
    id_role = user.get("id_role")
    assert isinstance(id_role, int)

    # checks user infomrations
    response = client.get("/user/info/%s" % id_role)

    name = user.get("prenom_role", "")
    last_name = user.get("nom_role", "")
    assert (last_name + " " + name) in response.text

    # delete user
    response = client.get("/users/delete/%s" % id_role)
    assert response.status_code == 200

    # we can't check for a 404 because the URL with a bad
    # id raises a 500
    response = client.get("/user/info/%s" % id_role)
    assert response.status_code != 200
