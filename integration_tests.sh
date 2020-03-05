#!/usr/bin/env bash

source "integration_tests/base.sh"

function help() {
    echo ""
    echo "Usage: ./integrations_test.sh <subcommand>"
    echo ""
    echo "Subcommands:"
    echo ""
    echo "    setup   Setup the testing environment, installing dependancies"
    echo "    run_all Run all tests"
    echo ""
}

set +o nounset
subcommand=$1
set -o nounset
case "$subcommand" in

"")
    echo ""
    echo "You must pass at least one argument: the subcommand"
    help
    ;;

"-h" | "--help")
    help
    ;;

setup)
    ./integration_tests/setup_test_environ.sh
    ;;

run_all)
    ./integration_tests/run_all_tests.sh
    ;;

manual_run)
    echo ""
    echo "Manually set the proper env variables (listed in settings.ini.sample), then types:"
    echo ""
    echo "    source \"${VENV_DIR}/bin/activate\""
    echo "    pytest \"integration_tests\""
    echo ""
    echo "You can load settings.ini manually too:"
    echo ""
    echo "    source \"settings.ini\""
    echo "    export \$(grep -v '^#' 'settings.ini' | cut -d= -f1)"
    echo ""
    ;;
*)
    echo ""
    echo "Unknown argument \`$subcommand'" >&2
    help
    exit 1
    ;;
esac
