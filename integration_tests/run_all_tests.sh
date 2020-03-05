#!/usr/bin/env bash

source "integration_tests/base.sh"

set +o nounset
source "${VENV_DIR}/bin/activate"
set -o nounset

pytest "$TEST_DIR"
