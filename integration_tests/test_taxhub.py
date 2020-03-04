import json

import requests

import pytest
from http_client import taxhub_client as unlogged_client


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
        Asserts if home page '/' return a success code 200
    '''
    unlogged_client.check_status('/', 200)


def test_login(unlogged_client):
    '''
        Asserts if login process is sucessful
    '''
    assert unlogged_client.login().status_code == 200


def test_apis(client):
    '''
        test_api tests if some chosen api (modules, occtax, users, ...) url return a success code 
    '''
    # api (url, test) definitions
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
        assert response.status_code == 200
        text = response.text
        assert test in text


def test_static_files(client):
    '''
        Checks if some static files can be reached
    '''

    assert client.check_status(
        "static/node_modules/angular-ui-bootstrap/dist/ui-bootstrap.js", 200
    )
    assert client.check_status(
        "static/node_modules/angularjs-toaster/toaster.min.css", 200
    )
    # wrong url leads to 404
    assert client.check_status("static/nimportequoi.min.css", 404)


# process to 
#   - create a list
#   - add id_nom
#   - remove all id_nom
#   - remove list (api DELETE list is missing TODO in taxhub)

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
