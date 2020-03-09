import sys
import tempfile
import uuid

import sh

from pathlib import Path


from build_tools.fs_utils import (
    ROOT_DIR,
    clone_git_repository,
    create_deb_fs_tree,
    in_temp_dir,
    package_deb_tree,
    move_package_to_build_dir,
    copy_files,
    in_dir,
)

from build_tools.sh_utils import ensure_npm


def build_usershub_deb(
    version,
    release,
    keep_temp_dir,
    temp_dir,
    dest_dir,
    arch,
    usershub_repo_uri,
    usershub_checkout,
):

    with in_temp_dir(root=temp_dir, delete=not keep_temp_dir) as dir_path:

        clone_git_repository(usershub_repo_uri, usershub_checkout, dir_path)

        # Build static files
        print("Build static files")
        repo_dir = dir_path / "UsersHub"
        static_dir = repo_dir / "app/static"
        required_npm_version = (static_dir / ".nvmrc").read_text()
        npm_run = ensure_npm(required_npm_version)
        with in_dir(static_dir):
            npm_run("ci")

        # Create an skeleton file system for the deb file from the template
        deb_tree_path = create_deb_fs_tree(
            template=str(ROOT_DIR / "deb_packages_files/usershub/"),
            output_dir=str(dir_path),
            version=version,
            release=release,
            architecture=arch,
        )

        # Populate it
        code_dir = deb_tree_path / "usr/share/usershub"
        copy_files(
            {
                repo_dir / "app": code_dir / "app",
                repo_dir / "server.py": code_dir,
                repo_dir / "requirements.txt": code_dir,
            }
        )
        # Zip the package and copy it
        deb_package = package_deb_tree(deb_tree_path)
        move_package_to_build_dir(deb_package, dest_dir)
