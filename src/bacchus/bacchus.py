#!/usr/bin/env python3

# Copyright 2018 Charles Daniels

#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:

#  1. Redistributions of source code must retain the above copyright notice,
#  this list of conditions and the following disclaimer.

#  2. Redistributions in binary form must reproduce the above copyright notice,
#  this list of conditions and the following disclaimer in the documentation
#  and/or other materials provided with the distribution.

#  3. Neither the name of the copyright holder nor the names of its
#  contributors may be used to endorse or promote products derived from this
#  software without specific prior written permission.

#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.


version = "0.0.1"

descr = """

Bacchus: the god of the grape harvest, winemaking and wine, of ritual madness,
fertility, theatre and religious ecstasy. Now also a tool for managing
WINE prefixes from a convenient command-line utility! See the variable
config_defaults for configuration options. Configuration is usually stored
in ~/.config/bacchus/bacchus.toml on Linux.

"""

import argparse
import logging
import sys
import os
import traceback
import appdirs
import toml
import subprocess
import datetime
import stat

# Note, these are the default values for the configuration file, which is
# usually ~/.config/bacchus/bacchus.toml.

config_defaults = {
    "default_winearch": "win32",   # default WINEARCH value
    "prefix_dir": "~/.bacchus/",   # dir where prefixes should be created
    "bin_dir":  "~/bin"            # dir where launcher binaries should go
}

def read_config_key(key):
    config_dir = os.path.join(appdirs.user_config_dir(), "bacchus")
    config_file = os.path.join(config_dir, "bacchus.toml")

    logging.debug("fetch {} from config".format(key))

    contents = {}

    with open(config_file, "r") as f:
        contents = toml.load(f)
        logging.debug("loaded config file OK")

    value = None
    if key in contents:
        value = contents[key]
    elif key in config_defaults:
        logging.debug("key not in config file, using default value")
        value = config_defaults[key]
    else:
        raise ValueError("Invalid config key: {}".format(key))

    logging.debug("Read value '{}' for key '{}'".format(value, key))

    value = os.path.expanduser(value)

    return value

def setup_logging(level=logging.INFO):
    logging.basicConfig(level=level,
            format='%(levelname)s: %(message)s',
            datefmt='%H:%M:%S')

def log_exception(e):
    logging.error("Exception: {}".format(e))
    logging.debug("".join(traceback.format_tb(e.__traceback__)))

def get_prefix_dir(prefix):
    prefix_prefix_dir = read_config_key("prefix_dir")
    prefix_dir = os.path.join(prefix_prefix_dir, prefix)
    return prefix_dir

def ensure_prefix(prefix):
    logging.debug("ensure prefix {} exists".format(prefix))

    prefix_dir = get_prefix_dir(prefix)

    if not os.path.exists(prefix_dir):
        logging.debug("creating {}".format(prefix_dir))
        os.makedirs(prefix_dir, exist_ok=True)

def run_command(command, env):

    logging.debug("execute command '{}' with env '{}'".format(command, env))

    # add default environment variables
    for key in os.environ:
        if key not in env:
            env[key] = os.environ[key]

    # execute the command
    logging.info("Executing '{}'... ".format(' '.join(command)))
    process = subprocess.Popen(command,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)

    # collect output
    stdout, stderr = process.communicate()
    stdout         = stdout.decode("utf8")
    stderr         = stderr.decode("utf8")

    # handle error conditions
    if process.returncode != 0:
        logging.error("standard out:")
        for line in stdout.split("\n"):
            logging.error("\t{}".format(line))
        logging.error("standard error:")
        for line in stderr.split("\n"):
            logging.error("\t{}".format(line))

        # TODO: should use a more descriptive exception here
        raise AttributeError("Command execution failed: '{}'".format(command))

def invoke_winecfg(prefix, winearch):

    ensure_prefix(prefix)

    logging.debug("Invoking winecfg on prefix {} and arch {}"
            .format(prefix, winearch))

    run_command(["winecfg"],
            env={
                "WINEARCH": winearch,
                "WINEPREFIX": get_prefix_dir(prefix)
            })

def invoke_wine(prefix, winearch, commands):

    ensure_prefix(prefix)

    logging.debug("Invoking command '{}' on prefix {} and arch {}"
            .format(commands, prefix, winearch))

    command = ["wine"]
    for c in commands:
        command.append(c)

    run_command(command,
            env={
                "WINEARCH": winearch,
                "WINEPREFIX": get_prefix_dir(prefix)
                })

def invoke_winetricks(prefix, winearch, commands):

    ensure_prefix(prefix)

    logging.debug("Invoking winetricks command '{}' on prefix {} and arch {}"
            .format(commands, prefix, winearch))

    command = ["winetricks"]
    for c in commands:
        command.append(c)

    run_command(command,
            env={
                "WINEARCH": winearch,
                "WINEPREFIX": get_prefix_dir(prefix)
                })

def generate_launcher(prefix, winearch, target, name=None):

    ensure_prefix(prefix)

    s = ""
    logging.debug("Generating launcher for file '{}'".format(target))

    # make sure the launcher dir exists
    launcher_dir = os.path.join(get_prefix_dir(prefix), "bacchus")
    if not os.path.exists(launcher_dir):
        logging.debug("Creating {}".format(launcher_dir))
        os.makedirs(launcher_dir, exist_ok=True)

    parent = os.path.dirname(target)

    # generate a name if needed
    if name is None:
        name = os.path.basename(target)
        if '.' in name:
            # strip extension
            name = '.'.join(name.split('.')[:1])
        logging.debug("generated name {}".format(name))

    launcher_file = os.path.join(launcher_dir, name)
    logging.debug("launcher file is {}".format(launcher_file))

    # write the launcher
    with open(launcher_file, 'w') as f:
        f.write("#!/bin/sh\n")
        f.write("\n")
        f.write("# Launcher generated by bacchus at {}\n\n"
                .format(datetime.datetime.now()))
        f.write('cd "{}"\n'.format(parent))
        f.write("export WINEARCH={}\n".format(winearch))
        f.write("export WINEPREFIX={}\n".format(get_prefix_dir(prefix)))
        f.write("wine ./{}\n".format(os.path.basename(target)))

    # mark executable
    os.chmod(launcher_file, os.stat(launcher_file).st_mode | stat.S_IEXEC)

    logging.info("Wrote launcher to '{}'".format(launcher_file))

def generate_links(prefix, target):
    launcher_dir = os.path.join(get_prefix_dir(prefix), "bacchus")

    if not os.path.exists(launcher_dir):
        logging.info("No launcher exist for prefix '{}'".format(prefix))
        return

    for launcher in os.listdir(launcher_dir):
        dest_path = os.path.join(read_config_key("bin_dir"), launcher)
        src_path = os.path.join(launcher_dir, launcher)

        if os.path.exists(dest_path):
            logging.info("'{}' already exists, overwriting... "
                    .format(dest_path))
            os.unlink(dest_path)

        os.symlink(src_path, dest_path)
        logging.info("Created symlink '{}' -> '{}'"
                .format(src_path, dest_path))


def main():

    parser = argparse.ArgumentParser(description=descr)

    parser.add_argument("--prefix", "-p", required=True, type=str,
            help="Specify the prefix you wish to work with. " +
            "Note that this is just the prefix name, not it's path")

    parser.add_argument("--winearch", "-a", default=None,
            help="Override configured default WINEARCH")

    parser.add_argument("--verbose", "-v", default=False,
            action="store_true", help="Display verbose log messages.")

    parser.add_argument("--name", "-n", default=None,
            help="Specify launcher name. Ignored for any action "+
            "except for --launcher.")

    action = parser.add_mutually_exclusive_group(required=True)

    action.add_argument("--winecfg", "-c", default=False,
            action="store_true", help="Run winecfg on the prefix.")

    action.add_argument("--run", "-r", default=None, nargs="+",
            help="Run a command through WINE. Hint: taskmgr runs " +
            "task manager, explorer runs explorer.exe.")

    action.add_argument("--where", "-w", default=False, action="store_true",
            help="Display the fully qualified path to the prefix.")

    action.add_argument("--winetricks", "-t", default=None, nargs="+",
            help="Invoke winetricks on the specified prefix.")

    action.add_argument("--launcher", "-l", default=None,
            help="Generate a launcher script for the specified file.")

    action.add_argument("--link", "-L", default=False,
            action="store_true", help="Symlink all launchers for the " +
            "specified prefix into the configured bin directory. " +
            "Note that if the destination file exists, it will be " +
            "overwritten silently.")

    parser.add_argument('--version', action='version', version=version)

    args = parser.parse_args()

    if args.verbose:
        setup_logging(level=logging.DEBUG)
    else:
        setup_logging()

    if args.winearch is None:
        args.winearch = read_config_key("default_winearch")

    try:
        if args.winecfg:
            invoke_winecfg(args.prefix, args.winearch)

        elif args.run is not None:
            invoke_wine(args.prefix, args.winearch, args.run)

        elif args.where:
            sys.stdout.write(get_prefix_dir(args.prefix))
            sys.stdout.write("\n")
            sys.stdout.flush()

        elif args.winetricks is not None:
            invoke_winetricks(args.prefix, args.winearch, args.winetricks)

        elif args.launcher is not None:
            generate_launcher(
                    prefix = args.prefix,
                    winearch = args.winearch,
                    target = args.launcher,
                    name = args.name)

        elif args.link:
            generate_links(args.prefix, read_config_key("bin_dir"))


    except Exception as e:
        log_exception(e)
        sys.exit(1)


if __name__ == "__main__":
    main()
