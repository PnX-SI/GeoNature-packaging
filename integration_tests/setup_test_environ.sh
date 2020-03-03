#!/usr/bin/env bash

source "integration_tests/base.sh"

# Ensure we have at least Python3.5
if [[ ! $(command -v python3.5) ]]; then
    echo "Python 3.5+ is required to run the integration tests" 1>&2
    exit 1
fi

# If we are in a venv, make sure it's suitable, and use it
venv=$(python -c 'import sys; print(getattr(sys, "real_prefix", ""))')
if [[ $venv ]]; then
    echo "Current in a venv '${VENV}', using that instead of creating one."
    python_version=$(python -V 2>&1 | cut -d\  -f 2) # python 2 prints version to stderr
    version=(${python_version//./ })                 # make an version parts array
    if [[ ${version[0]} -lt 3 ]] || [[ ${version[0]} -eq 3 && ${version[1]} -lt 5 ]]; then
        echo "This virtualenv uses Python ${python_version}, but integration testing requires 3.5+ " 1>&2
        exit 1
    fi
# If we are not in a venv, check if we can create one, create it
# and use it
else
    #
    if [[ ! -d $VENV_DIR ]]; then
        echo "'${VENV_DIR}' virtualenv does not exist. Creating it."

        # return code 1 => no venv module
        $PYTHON_EXE -m venv >/dev/null 2>&1 && return_code=$? || return_code=$?
        if [[ $return_code == 1 ]]; then
            echo "Python doesn't have the 'venv' module. Makes sure to have it installed. On debian, 'apt install pythonX.Y-venv'.with X.Y being your version of Python" 1>&2
            exit 1
        fi
    fi

    echo "Activate the venv"
    python3.5 -m venv $VENV_DIR
    set +o nounset
    source "${VENV_DIR}/bin/activate"
    set -o nounset
fi

# Starting from here, we are in a virtualenv
echo "Install dependancies in the ${VENV_DIR}"
pip install --upgrade pip
pip install requests pytest bs4

echo -e "\e[32m\nYou can now run tests: source ${VENV_DIR}/bin/activate; pytest integration_tests."
echo "Check the settings.ini.sample for the available configuration options. Make a settings.ini with the ones you wish to set or use env variables."
