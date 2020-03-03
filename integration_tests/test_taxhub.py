import json

import requests

import pytest
from http_client import taxhub_client as unlogged_client


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


def test_login(unlogged_client):
    assert unlogged_client.login().status_code == 200


def test_all_api(client):
    urls = [
        (
            "api/taxref/?classe=&famille=&is_inbibtaxons=false&is_ref=false&limit=25&order=asc&orderby=nom_complet&ordre=&page=1&phylum=&regne=",
            "items",
        ),
        (
            "api/bibnoms/?is_inbibNoms=false&is_ref=false&limit=50&order=asc&orderby=taxref.nom_complet&page=1",
            "items",
        ),
        ("api/biblistes/", "data"),
    ]
    for (url, test) in urls:
        response = client.get(url)
        json = response.json()
        text = response.text
        assert response.status_code == 200
        assert test in text


def test_static_files(client):
    assert client.check_status(
        "static/node_modules/angular-ui-bootstrap/dist/ui-bootstrap.js", 200
    )
    assert client.check_status(
        "static/node_modules/angularjs-toaster/toaster.min.css", 200
    )
    assert client.check_status("static/nimportequoi.min.css", 404)


# def test_create_liste(client):

#     data_list = {
#         'id_liste':1,
#         "nom_liste":"Test",
#         "desc_liste":"Liste de test",
#         "picto":"images/pictos/favicon.png",
#         "regne":"Animalia",
#         "group2_inpn":"Mamifères"
#     }

#     response = client.post('api/biblistes/' + str(data_list['id_liste']), json=data_list)
#     assert response.status_code == 200

#     data_add_nom = [ 2 ]

#     response = client.post('api/biblistes/addnoms/' + str(data_list['id_liste']), json=data_add_nom)
#     assert response.status_code == 200

#     response = client.get('api/biblistes/deletenoms/' + str(data_list['id_liste']))
#     assert response.status_code == 200
