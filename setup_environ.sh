#!/usr/bin/env bash

# Configuration
###############################

set -E -o errexit -o pipefail -o nounset
IFS=$'\n'
shopt -s dotglob

# Debug mode trace all commands from the script
if [[ ! ${GEONATURE_CI_DEBUG:-} =~ ^(false|0|)$ ]]; then
    echo "$GEONATURE_CI_DEBUG is set => printing all commands"
    set -o xtrace
fi

# Find the directory of this script, no matter where we are called from
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done

# Generate a few default paths
ROOT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
TEST_DIR="${ROOT_DIR}/integration_tests"
CONFIG_FILE="${ROOT_DIR}/settings.ini"

# Load env vars from the conf file it it exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    export $(grep -v "^#" "$CONFIG_FILE" | cut -d= -f1)
fi

function installed_python() {
    compgen -c python | grep -v "[-m]" | sort
}

function installed_python_versions() {
    for py in $(installed_python); do
        $py --version 2>/dev/null
    done | cut -f2 -d " "
}

# Make sure we have some default values
export DEBUG=${GEONATURE_CI_DEBUG:-}
DEFAULT_VENV_DIR="$ROOT_DIR/venv"
export VENV_DIR=${GEONATURE_CI_VENV_DIR:-$DEFAULT_VENV_DIR}
most_recent_python=$(installed_python | tail -n 1)
export PYTHON_EXE=${GEONATURE_CI_PYTHON:-$most_recent_python}

# Setup
###############################

# If we are in a venv, make sure it's suitable, and use it
prefix=$(python -c 'import sys; print(getattr(sys, "real_prefix", ""))')
venv=${VIRTUAL_ENV:-$prefix}
if [[ $venv ]]; then
    echo "Currently in a venv '${venv}', using that instead of creating one."
    python_version=$(python -V 2>&1 | cut -d\  -f 2) # python 2 prints version to stderr
    if dpkg --compare-versions "$python_version" "<=" "3.6"; then
        echo "This virtualenv uses Python ${python_version}, but integration testing requires 3.6+. Create a new virtualenv or let the script create one for you." 1>&2
        exit 1
    fi
    PYTHON_EXE=$(which python)

# If we are not in a venv, create it and use it
else
    # Ensure we have at least Python3.6
    python_version=$($PYTHON_EXE -V 2>&1 | cut -d\  -f 2) # python 2 prints version to stderr
    if dpkg --compare-versions "$python_version" "<=" "3.6"; then
        echo "Insalled python version to old. Installing 3.6"
        sudo apt install python3.6 -y
    fi

    # Ensure we have venv installed
    set +o errexit
    $PYTHON_EXE -m venv >/dev/null 2>&1
    if [[ $? == 1 ]]; then
        # Install dependancies for venv
        sudo apt install python3-venv -y
        if dpkg --compare-versions "$python_version" "==" "3.7"; then
            sudo apt install python3.7-venv -y
        fi
        if dpkg --compare-versions "$python_version" "==" "3.8"; then
            sudo apt install python3.8-venv -y
        fi
    fi
    set -o errexit

    # clean artifacts of a bad venv
    if [[ -d "${VENV_DIR}" ]] && [[ ! -f "${VENV_DIR}/bin/activate" ]]; then
        echo "Corrupted venv detected, deleting it"
        rm -fr "${VENV_DIR}"
    fi

    # Actually create the venv
    if [[ ! -d "${VENV_DIR}" ]]; then
        echo "'${VENV_DIR}' virtualenv does not exist. Creating it."
        $PYTHON_EXE -m venv "$VENV_DIR"
    fi

    echo "Activate the venv"
    set +o nounset
    source "${VENV_DIR}/bin/activate"
    set -o nounset
fi

# Starting from here, we are in a virtualenv
echo "Install dependancies in the venv in ${VENV_DIR}"
pip install --upgrade pip
pip install -r "$ROOT_DIR/requirements.txt"

echo -e "\e[32m\nYou can now test and package. Check the README."
