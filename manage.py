#!/usr/bin/env python

from pathlib import Path

import os
import sh
import click
import configparser

import pytest

from build_tools.build_geonaturedb import build_geonaturedb_deb
from build_tools.build_usershub import build_usershub_deb
from build_tools.fs_utils import ROOT_DIR, in_dir

@click.group()
def cli():
    pass

@cli.command()
@click.option(
    "--dest-dir",
    default=ROOT_DIR / "build",
    help="The directory where to output the package",
    show_default=True,
)
@click.option(
    "--temp-dir",
    default=None,
    help=(
        "The directory where to create the temporary files. "
        "Default is to create a sub dir in the system temporary directory."
    ),
)
@click.option(
    "--keep-temp-dir/--delete-temp-dir",
    default=False,
    show_default=True,
    help="Do not delete the temp dir after in the end. Useful for debugging.",
)
@click.option(
    "--usershub-repo-uri",
    show_default=True,
    default="https://github.com/PnX-SI/UsersHub.git",
    help="The URI to get the usershub repo from. It can be a local path.",
)
@click.option(
    "--taxhub-repo-uri",
    show_default=True,
    default="https://github.com/PnX-SI/TaxHub.git",
    help="The URI to get the taxhub repo from. It can be a local path.",
)
@click.option(
    "--geonature-repo-uri",
    show_default=True,
    default="https://github.com/PnX-SI/GeoNature.git",
    help="The URI to get the geonature repo from. It can be a local path.",
)
@click.option(
    "--usershub-checkout",
    default="master",
    show_default=True,
    help="The git reference to checkout after cloning the usershub repo",
)
@click.option(
    "--taxhub-checkout",
    default="master",
    show_default=True,
    help="The git reference to checkout after cloning the usershub repo",
)
@click.option(
    "--geonature-checkout",
    default="master",
    show_default=True,
    help="The git reference to checkout after cloning the usershub repo",
)
@click.option(
    "--distributions",
    default="stretch,buster,xenial,bionic",
    show_default=True,
    help="Coma separated values of the debian and ubuntu distribution codes to build deb for",
)
@click.argument(
    "project",
    metavar="PROJECT_NAME",
    type=click.Choice(["geonaturedb", "usershub"], case_sensitive=False),
)
def build(
    project,
    keep_temp_dir,
    temp_dir,
    dest_dir,
    usershub_repo_uri,
    taxhub_repo_uri,
    geonature_repo_uri,
    usershub_checkout,
    taxhub_checkout,
    geonature_checkout,
    distributions
):
    """Build a package for the given project, version and release.

        Available projects:

            - geonaturedb
    """
    distributions = distributions.split(',')
    if project == "geonaturedb":
        build_geonaturedb_deb(
            keep_temp_dir,
            temp_dir,
            dest_dir,
            usershub_repo_uri,
            taxhub_repo_uri,
            geonature_repo_uri,
            usershub_checkout,
            taxhub_checkout,
            geonature_checkout,
            distributions
        )

    if project == "usershub":
        build_usershub_deb(
            keep_temp_dir,
            temp_dir,
            dest_dir,
            usershub_repo_uri,
            usershub_checkout,
            distributions
        )

@cli.command()
@click.option(
    "--settings",
    type=Path,
    default=ROOT_DIR / "settings.ini",
    help="A settings file to configure the tests with",
)
@click.argument(
    "path",
    metavar="TESTS_PATH",
    type=Path,
    default=ROOT_DIR / "integration_tests",
)
def run_tests(
    path,
    settings,
):
    """ Load the configuration and run the tests

        This is the equivalent of settings all the
        env variables manually, activate the venv,
        then at the root of the project do:

        pytest integration_tests

        Do so if you need more flexibility such as passing
        options to pytest itself.

    """
    # Execute the tests, respecting the config file
    with settings.open(encoding="utf8") as f:
        config = configparser.ConfigParser()
        config.optionxform = str # don't lowercase keys
        config.read_string('[main]\n'+ f.read())
        os.environ = {**config['main'], **os.environ}
        with in_dir(ROOT_DIR):
            pytest.main([str(path)])

if __name__ == "__main__":
    cli()
