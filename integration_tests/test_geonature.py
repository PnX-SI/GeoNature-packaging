import json

import requests
from bs4 import BeautifulSoup

import pytest
from http_client import geonature_client as unlogged_client


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
    

def test_page(client):
    '''
        Checks if home page contains 'GeoNature' as title and script files can be read

        Args:
            client : pytest fixture to process the test as a connected client 
    '''

    # response status is 200
    response = client.get("/")
    assert response.status_code == 200

    # init BeautifulSoup parser
    soup = BeautifulSoup(text, "html.parser")

    # test title
    assert soup.title.string == "GeoNature"

    # test script file 
    # (max_script_tested is used to limit the number of file to be tested)
    max_script_tested = 5
    for index, item in enumerate(soup.find_all("script")):
        if index > 5:
            break
        src = item.get("src")
        assert client.check_status(src, 200)


def test_api(client):
    '''
        test_api tests if some chosen api (modules, occtax, users, ...) url return a success code 
    '''

    # api urls definition
    urls = [
        "api/gn_commons/modules",
        "api/occtax/releves?limit=12",
        "api/users/menu/1"
    ]

    for url in urls:
        # test if api url returns a success code 200 
        assert client.check_status(url, 200)
