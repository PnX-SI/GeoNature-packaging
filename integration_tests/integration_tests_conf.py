'''
    Application HttpClient configurations  as SimpleNamespace for
        GEONATURE, TAXHUB, USERSHUB

    parameters are retrieved from environment and can be set in ../settings.ini

    url: root url for application
    test_login, test_login_passwword, application_id: login parameters
    login_url: api for login post request (slightly different amongst application)
    root_org_id: exemple for id_organism (needed for testing user creation / delete cycle)
'''

import os
from types import SimpleNamespace

GEONATURE_CONFIG = SimpleNamespace(
    url=os.environ.get("GEONATURE_URL", "http://127.0.0.0:8000"),
    test_login=os.environ.get("TEST_LOGIN", "admin"),
    test_password=os.environ.get("TEST_PASSWORD", "admin"),
    login_url=os.environ.get("GEONATURE_LOGIN_URL", "/api/auth/login"),
    application_id=os.environ.get("GEONATURE_APPLICATION_ID", "3"),
)

TAXHUB_CONFIG = SimpleNamespace(
    url=os.environ.get("TAXHUB_URL", "http://127.0.0.1:5000"),
    test_login=os.environ.get("TEST_LOGIN", "admin"),
    test_password=os.environ.get("TEST_PASSWORD", "admin"),
    login_url=os.environ.get("TAXHUB_LOGIN_URL", "/api/auth/login"),
    application_id=os.environ.get("TAXHUB_APPLICATION_ID", "2"),
)


USERSHUB_CONFIG = SimpleNamespace(
    url=os.environ.get("USERSHUB_URL", "http://127.0.0.1:5001"),
    test_login=os.environ.get("TEST_LOGIN", "admin"),
    test_password=os.environ.get("TEST_PASSWORD", "admin"),
    login_url=os.environ.get("USERSHUB_LOGIN_URL", "/pypn/auth/login"),
    application_id=os.environ.get("USERSHUB_APPLICATION_ID", "1"),
    root_org_id=os.environ.get("USERSHUB_ROOT_ORG_ID", "0"),
)
