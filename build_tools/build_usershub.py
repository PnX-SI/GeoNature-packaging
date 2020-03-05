import sys
import tempfile

import sh

from pathlib2 import Path


from build_tools.fs_utils import (
    ROOT_DIR,
    clone_git_repository,
    create_deb_fs_tree,
    in_temp_dir,
    package_deb_tree,
    move_package_to_build_dir,
)


def build_usershub_db_deb(
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

    with in_temp_dir(root=temp_dir, delete=not keep_temp_dir) as dir_path:

        clone_git_repository(usershub_repo_uri, usershub_checkout, dir_path)
        clone_git_repository(taxhub_repo_uri, taxhub_checkout, dir_path)
        clone_git_repository(geonature_repo_uri, geonature_checkout, dir_path)
        deb_tree_path = create_deb_fs_tree(
            template=str(ROOT_DIR / "deb_packages_files/geonaturedb/"),
            output_dir=str(dir_path),
            version=version,
            release=release,
            architecture=arch,
        )
        deb_package = package_deb_tree(deb_tree_path)
        move_package_to_build_dir(deb_package, dest_dir)
