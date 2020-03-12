import os
import sys
import tarfile
import tempfile
from contextlib import contextmanager
from hashlib import md5

import sh
from cookiecutter.generate import generate_files
from pathlib import Path

ROOT_DIR = Path(__file__).absolute().parent.parent


@contextmanager
def in_dir(directory):
    """ Cd in a dir during a 'with' block

        Example:

            >>> with in_dir('/'):
            ...     # here we are in '/'
            >>> # here we are not in '/' anymore
    """
    old_dir = os.getcwd()
    os.chdir(str(directory))
    try:
        yield Path(old_dir)
    finally:
        os.chdir(old_dir)


@contextmanager
def in_temp_dir(root=None, delete=True):
    """ Create a temp dir, and cd to it

        Example:

            >>> with in_temp_dir() as temp_dir:
            ...     # here we are in a automatically created temporary dir
            >>> # here we are not in it anymore, and it's been deleted
    """
    temp_dir = Path(tempfile.mkdtemp(dir=root))

    with in_dir(temp_dir):
        try:
            yield temp_dir
        finally:
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


def create_deb_fs_tree(template, output_dir, distribution):

    print("Create deb file system tree")
    # Use cookiecutter to turn the template into a real directory tree
    template = Path(template)
    unziped_package = Path(
        generate_files(  # fonction de cookiecutter non documentée (cf code)
            repo_dir=str(template),
            context={
                "cookiecutter": {}, # cookiecutter requires to have "cookiecutter" in the name of the template name
                "distribution": distribution,
                "checksums": recursive_md5(next(template.iterdir())),
            },
            overwrite_if_exists=True,
            output_dir=output_dir,
        )
    )

    # dpkg-deb --build doesn't want anything with 777 permissions
    for path in (unziped_package / "debian").rglob("*"):
        path.chmod(0o775)

    return unziped_package


def recursive_md5(directory):
    """ Get the recursive checksums of all the files in directory

        To match the format of the md5sums file in a deb packages,
        the path are yielded relative to the directory

        The DEBIAN directory is ignored.
    """
    for path in Path(directory).rglob("*"):
        if path.is_file():
            checksum = md5(path.read_bytes()).hexdigest()
            path = str(path).replace(str(directory).rstrip("/") + "/", "")
            yield path, checksum


def package_deb_tree(directory):
    """ Apply the dpkg build process to a debian complient FS tree """
    try:
        print("Zip deb package")
        with in_dir(directory):
            sh.dpkg_buildpackage("--no-sign", "--build=binary")
    except sh.ErrorReturnCode as e:
        sys.exit("Error while finalizing up the package with dpkg: %s" % e)

    return next(directory.parent.glob("*.deb"))


def move_package_to_build_dir(deb_package, build_dir):
    """ Create the build dir, then move the deb package to it """
    sh.mkdir("-p", build_dir)
    sh.cp(deb_package, build_dir)
    print(
        'Deb package is available at "%s"' % (Path(build_dir) / Path(deb_package).name)
    )


def copy_files(source_to_dest):
    """ Copy rescursively directories

        `source_to_dest` must be a dict such as keys are
        directories or files to be copied and values are destinations where
        to copy them to.

        If a key is a directory, it is not copied, but its content is.

        Values must be directories, they will the content of the source directory
        or the source file.

        Any missing directories provided as values will be recursively created.
    """
    for source, dest in source_to_dest.items():
        source = Path(source)
        if not source.is_file() and not source.is_dir():
            sys.exit(
                "Unable to copy '{0}' to '{1}': '{0}' is not a valid file or directory".format(
                    source, dest
                )
            )
        sh.mkdir(dest, "-p")
        if source.is_file():
            sh.cp(source, dest)
        else:
            for content in source.iterdir():
                sh.cp(content, dest, "-r")

