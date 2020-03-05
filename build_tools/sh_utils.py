import shlex

import sh
import re


def command_exists(command):
    try:
        sh.bash("-c", "command -v %s" % shlex.quote(command))
        return True
    except sh.ErrorReturnCode:
        return False


def ensure_nvm():
    """ Make sure nvm is installed """
    if not command_exists("nvm"):
        print("Install nvm")
        sh.bash(
            sh.wget(
                "-qO-",
                "https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh",
            )
        )


def ensure_npm(version):
    """ Make sure this npm version is installed

        This return a function to execute node command for this particular node
        version.
    """
    ensure_nvm()
    try:
        sh.bash(
            "-c",
            "source ~/.nvm/nvm.sh; nvm install {}".format(shlex.quote(str(version))),
        )
    except sh.ErrorReturnCode:
        sys.exit('Unable to install node version "{}"'.format(version))

    def npm_run(*args):
        """ Run an npm command with the given npm version """
        sh.bash(
            "-c",
            "source ~/.nvm/nvm.sh; nvm exec {} npm {}".format(
                shlex.quote(str(version)), " ".join(args)
            ),
        )

    return npm_run
