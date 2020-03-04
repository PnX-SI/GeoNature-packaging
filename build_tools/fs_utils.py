import os
import sys
import tarfile
import tempfile
from contextlib import contextmanager
from hashlib import md5

import sh
from cookiecutter.generate import generate_files
from pathlib2 import Path

ROOT_DIR = Path(__file__).absolute().parent.parent


@contextmanager
def in_temp_dir(root=None, delete=True):
    """ Create a temp dir, and cd to it """
    temp_dir = Path(tempfile.mkdtemp(dir=root))
    old_dir = os.getcwd()
    os.chdir(str(temp_dir))
    try:
        yield temp_dir
    finally:
        os.chdir(old_dir)
        if delete and temp_dir.absolute() != "/":
            sh.rm(temp_dir, "-fr")
        else:
            print('Temporary files kept in "%s"' % temp_dir)


def clone_git_repository(uri, ref, dest):
    """ Clone a git repository and checkout a branch or tag

        Definitly eexit the build if it fails. E.G: the branch doesn't exist.
    """
    print('Cloning "{}" in "{}"'.format(uri, dest))
    try:
        # We limit the number of commits to look up to 200 to speed up things
        # Espacially for geonature which is a big repository
        sh.git.clone(uri, "--depth", "200", "--branch", ref)
    except sh.ErrorReturnCode as e:
        sys.exit("Cloning repository failed: %s" % e)


def create_deb_fs_tree(template, output_dir, version, release, architecture):

    # Use cookiecutter to turn the template into a real directory tree
    template = Path(template)
    unziped_package = Path(
        generate_files(
            repo_dir=str(template),
            context={
                "package_version": version,
                "package_release": release,
                "package_architecture": architecture,
                "checksums": recursive_md5(next(template.iterdir())),
            },
            overwrite_if_exists=True,
            output_dir=output_dir,
        )
    )

    # cookiecutter requires to have "cookiecutter_" in the name of the
    # template, so we added it, but we remove it in the final build
    clean_name = str(unziped_package).replace("cookiecutter_", "")
    unziped_package.rename(clean_name)
    unziped_package = Path(clean_name)


def recursive_md5(directory):
    """ Get the recursive checksums of all the files in directory

        To match the format of the md5sums file in a deb packages,
        the path are yielded relative to the directory

        The DEBIAN directory is ignored.
    """
    for path in Path(directory).rglob("*"):
        if path.is_file() and "DEBIAN" not in str(path):
            checksum = md5(path.read_bytes()).hexdigest()
            path = str(path).replace(str(directory).rstrip("/") + "/", "")
            yield path, checksum
