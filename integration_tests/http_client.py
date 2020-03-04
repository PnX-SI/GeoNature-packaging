import sys

import requests
from requests.exceptions import ConnectionError

import pytest
from integration_tests_conf import GEONATURE_CONFIG, TAXHUB_CONFIG, USERSHUB_CONFIG


class HttpClient:
    '''
    Http client wraps methods to process requests and tests on applications (Usershub, Taxhub, Geonature)

    Args:
        conf: configuration for the application (url, ect..)
        session: requests Session()
    
    '''

    def __init__(self, service_conf):
        '''
        Constructor : instanciate an HttpClient for an application

        Args: 
            service conf: configuration for the application (url, ect..)
        '''
        self.conf = service_conf
        self.session = requests.Session()

    def ping(self):
        '''
        Try to process a get requests on application root url

        Returns:
            True on succes, else False

        '''
        try:
            self.get(self.conf.url).status_code
        except ConnectionError:
            return False
        return True

    def join_url(self, start, end):
        '''
        Returns a url as <start>/<end> and checks for avoids doublons for '/'

        Args:
            start: url first part
            end: url last part
        '''
        return start.rstrip("/") + "/" + end.lstrip("/")

    def get(self, path, *args, **kwargs):
        '''
        Process a get request 

        Args:
            path: relative path for the url, requested url will be ('<APPLICATION_URL>/<path>')
            *args: arguments for the request
            **args: named arguments for the request
        Returns:
            request response
        '''
        return self.session.get(self.join_url(self.conf.url, path), *args, **kwargs)

    def post(self, path, *args, **kwargs):
        '''
        Process a post request 

        See get method for arguments and returns
        '''
        return self.session.post(self.join_url(self.conf.url, path), *args, **kwargs)

    def put(self, path, *args, **kwargs):
        '''
        process a put request 

        See get method for arguments and returns

        '''
        return self.session.put(self.join_url(self.conf.url, path), *args, **kwargs)

    def patch(self, path, *args, **kwargs):
        '''
        Process a patch request 

        See get method for arguments and returns

        '''
        return self.session.patch(self.join_url(self.conf.url, path), *args, **kwargs)

    def delete(self, path, *args, **kwargs):
        '''
        Process a delete request 

        See get method for arguments and returns

        '''
        return self.session.delete(self.join_url(self.conf.url, path), *args, **kwargs)

    def check_status(self, path, code, *args, **kwargs):
        '''
        Process a get request and checks the response status_code equals a chosen code

        Args:
            path: relative path for the url, requested url will be ('<APPLICATION_URL>/<path>')
            code: response status code expected for this request 
            *args: arguments for the request
            **args: named arguments for the request
        '''
        return self.get(path, *args, **kwargs).status_code == code

    def login(self):
        '''
        Sends a post request to the application login route with login parameters

        Environments parameters 
            TEST_LOGIN,
            TEST_PASSWORD, 
            <APPLICATION>_LOGIN_URL
        are used to process a post request on the login route.
        These parameters can be set in ../settings.ini
 
        '''
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
        '''
            Tries to reach the application base url.
            In case of failure: abort the test process with pytest.exit
        '''
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
                    .format(self.conf.url)
                )
            )

    def __enter__(self):
        self.session.__enter__()
        return self

    def __exit__(self, *args, **kwargs):
        self.session.__exit__(*args, **kwargs)


@pytest.fixture
def usershub_client():
    '''
        Creates a client for USERSHUB
    '''
    with HttpClient(USERSHUB_CONFIG) as client:
        yield client


@pytest.fixture
def taxhub_client():
    '''
        Creates a client for TAXHUB
    '''
    with HttpClient(TAXHUB_CONFIG) as client:
        yield client


@pytest.fixture
def geonature_client():
    '''
        Creates a client for GEONATURE
    '''
    with HttpClient(GEONATURE_CONFIG) as client:
        yield client
