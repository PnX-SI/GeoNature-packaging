import sys

import requests
from requests.exceptions import ConnectionError

import pytest
from integration_tests_conf import GEONATURE_CONFIG, TAXHUB_CONFIG, USERSHUB_CONFIG


class HttpClient:
    def __init__(self, service_conf):
        self.conf = service_conf
        self.root = service_conf.url
        self.session = requests.Session()

    def ping(self):
        try:
            self.get(self.root).status_code
        except ConnectionError:
            return False
        return True

    def join_url(self, start, end):
        return start.rstrip("/") + "/" + end.lstrip("/")

    def get(self, path, *args, **kwargs):
        return self.session.get(self.join_url(self.root, path), *args, **kwargs)

    def post(self, path, *args, **kwargs):
        return self.session.post(self.join_url(self.root, path), *args, **kwargs)

    def put(self, path, *args, **kwargs):
        return self.session.put(self.join_url(self.root, path), *args, **kwargs)

    def patch(self, path, *args, **kwargs):
        return self.session.patch(self.join_url(self.root, path), *args, **kwargs)

    def delete(self, path, *args, **kwargs):
        return self.session.delete(self.join_url(self.root, path), *args, **kwargs)

    def check_status(self, url, code, *args, **kwargs):
        return self.get(url, *args, **kwargs).status_code == code

    def login(self):
        conf = self.conf
        return self.post(
            conf.login_url,
            json={
                "id_application": conf.application_id,
                "login": conf.test_login,
                "password": conf.test_login,
            },
        )

    def ping_or_die(self):
        if not self.ping():
            pytest.exit(
                (
                    (
                        "\n\nUnable to connect to {}. "
                        "\nMake sure you got the right URL "
                        "in the configuration variables. "
                        "\nIn doubt, test it in a web browser, "
                        "you should be able to access it if "
                        "you want the integration tests to "
                        "be able to it as well.\n"
                    )
                    .upper()
                    .format(self.root)
                )
            )

    def __enter__(self):
        self.session.__enter__()
        return self

    def __exit__(self, *args, **kwargs):
        self.session.__exit__(*args, **kwargs)


@pytest.fixture
def usershub_client():
    with HttpClient(USERSHUB_CONFIG) as client:
        yield client


@pytest.fixture
def taxhub_client():
    with HttpClient(TAXHUB_CONFIG) as client:
        yield client


@pytest.fixture
def geonature_client():
    with HttpClient(GEONATURE_CONFIG) as client:
        yield client
