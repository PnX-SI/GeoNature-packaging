import os
from types import SimpleNamespace

GEONATURE_CONFIG = SimpleNamespace(
    url=os.environ.get("GEONATURE_URL", "http://127.0.0.0:8000"),
    test_login=os.environ.get("TAXHUB_TEST_LOGIN", "admin"),
    test_password=os.environ.get("TAXHUB_TEST_PASSWORD", "admin"),
    login_url=os.environ.get("TAXHUB_LOGIN_URL", "/api/auth/login"),
    application_id=os.environ.get("TAXHUB_APPLICATION_ID", "3"),
)

TAXHUB_CONFIG = SimpleNamespace(
    url=os.environ.get("TAXHUB_URL", "http://127.0.0.1:5000"),
    test_login=os.environ.get("TAXHUB_TEST_LOGIN", "admin"),
    test_password=os.environ.get("TAXHUB_TEST_PASSWORD", "admin"),
    login_url=os.environ.get("TAXHUB_LOGIN_URL", "/api/auth/login"),
    application_id=os.environ.get("TAXHUB_APPLICATION_ID", "2"),
)


USERSHUB_CONFIG = SimpleNamespace(
    url=os.environ.get("USERSHUB_URL", "http://127.0.0.1:5001"),
    test_login=os.environ.get("USERSHUB_TEST_LOGIN", "admin"),
    test_password=os.environ.get("USERSHUB_TEST_PASSWORD", "admin"),
    login_url=os.environ.get("USERSHUB_LOGIN_URL", "/pypn/auth/login"),
    application_id=os.environ.get("USERSHUB_APPLICATION_ID", "1"),
    root_org_id=os.environ.get("USERSHUB_ROOT_ORG_ID", "0"),
)
