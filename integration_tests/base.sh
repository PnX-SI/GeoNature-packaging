#!/usr/bin/env bash

function set_bash_modes() {
    set -E -o errexit -o pipefail -o nounset
    IFS=$'\n'
    shopt -s dotglob
    # Debug mode trace all commands from the script
    if [[ ! ${GEONATURE_CI_DEBUG:-} =~ ^(false|0|)$ ]]; then
        echo "$GEONATURE_CI_DEBUG is set => printing all commands"
        set -o xtrace
    fi
}

set_bash_modes

# Find the directory of this script, no matter where we are called from
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
TEST_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
ROOT_DIR=$(dirname "$TEST_DIR")
CONFIG_FILE="${ROOT_DIR}/settings.ini"

# Load env vars from the conf file it it exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    export $(grep -v "^#" "$CONFIG_FILE" | cut -d= -f1)
fi

# Make sure we have some default value
export DEBUG=${GEONATURE_CI_DEBUG:-}
DEFAULT_VENV_DIR="/tmp/geonature_integration_testing_venv"
export VENV_DIR=${GEONATURE_CI_VENV_DIR:-$DEFAULT_VENV_DIR}
export PYTHON_EXE=${GEONATURE_CI_PYTHON:-"python3.5"}
