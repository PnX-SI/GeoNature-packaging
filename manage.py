#!/usr/bin/env python

import click  # See doc: https://click.palletsprojects.com

from build_tools.build_usershub import build_usershub_db_deb
from build_tools.fs_utils import ROOT_DIR


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
@click.option("--arch", default="amd64", help="The archictecture to release for")
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
@click.argument(
    "project",
    metavar="PROJECT_NAME",
    type=click.Choice(["geonaturedb"], case_sensitive=False),
)
@click.argument(
    "version", metavar="VERSION_NUMBER",
)
@click.argument(
    "release", metavar="RELEASE_NUMBER", type=int,
)
def build(
    project,
    version,
    release,
    keep_temp_dir,
    temp_dir,
    dest_dir,
    arch,
    usershub_repo_uri,
    taxhub_repo_uri,
    geonature_repo_uri,
    usershub_checkout,
    taxhub_checkout,
    geonature_checkout,
):
    """Build a package for the given project, version and release.

        Available projects:

            - geonaturedb
    """

    if project == "geonaturedb":
        build_usershub_db_deb(
            version,
            release,
            keep_temp_dir,
            temp_dir,
            dest_dir,
            arch,
            usershub_repo_uri,
            taxhub_repo_uri,
            geonature_repo_uri,
            usershub_checkout,
            taxhub_checkout,
            geonature_checkout,
        )


if __name__ == "__main__":
    cli()
