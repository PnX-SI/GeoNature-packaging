import requests

from integration_tests_conf import USERSHUB_URL


def test_home():
    ipdb.set_trace()
    response = requests.get(USERSHUB_URL)
    assert response.status_code == 302
