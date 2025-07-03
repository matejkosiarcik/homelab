#!/usr/bin/env python3

import argparse
import logging
import os
import re
import subprocess
import sys
from datetime import datetime
from os import path
from typing import List

start_datetime = datetime.now()
start_datestr = start_datetime.strftime(r"%Y-%m-%d_%H-%M-%S")
os.environ["START_DATE"] = start_datestr

server_dir = path.abspath(path.curdir)
server_name = path.basename(server_dir)
git_dir = path.abspath(path.join(server_dir, "..", ".."))
docker_apps_dir = path.join(server_dir, "docker-apps")
docker_apps_list_all = [x for x in next(os.walk(docker_apps_dir))[1] if not x.startswith(".") and path.isdir(path.join(docker_apps_dir, x))]

log_dir = path.join(path.expanduser("~"), ".homelab-logs", start_datestr)
log_file = path.join(log_dir, "log.txt")
os.makedirs(log_dir, exist_ok=True)

applist = []
dryrun = False
force = False
is_online = True
mode = ""

log = logging.getLogger()
log.setLevel(logging.INFO)
log.addHandler(logging.StreamHandler())
log.addHandler(logging.FileHandler(log_file))


def read_priority_apps_list() -> List[str]:
    with open(path.join(server_dir, "docker-apps", "priority.txt"), "r", encoding="utf-8") as file:
        lines = file.readlines()
    lines = [x.strip() for x in lines]
    lines = [re.sub(r"#.*$", "", x) for x in lines]
    lines = [x for x in lines if len(x) > 0]
    return lines


def main(argv: List[str]):
    global applist, dryrun, force, is_online, mode  # pylint: disable=global-statement
    parser = argparse.ArgumentParser(prog="main.sh")
    subparsers = parser.add_subparsers(dest="subcommand")
    subcommands = [
        subparsers.add_parser("build", help="Build docker images for all docker apps"),
        subparsers.add_parser("secrets", help="Create secrets for all docker apps"),
        subparsers.add_parser("deploy", help="Deploy all docker apps"),
        subparsers.add_parser("install", help="Install main server scripts (does not start docker-apps)"),
        subparsers.add_parser("start", help="Start all docker apps"),
        subparsers.add_parser("stop", help="Stop all docker apps"),
    ]
    for subcommand in subcommands:
        subcommand_name = subcommand.prog.split(" ")[-1]
        subcommand.add_argument("-n", "--dry-run", action="store_true", help="Dry run")
        subcommand.add_argument("-f", "--force", action="store_true", help="Force")
        subcommand.add_argument("--only", type=str, help=f"A list of apps to {subcommand_name}")
        # if subcommand_name in ["build", "deploy", "start", "stop"]:
        #     subcommand.add_argument("--parallel", type=int, help=f"A number of simultaneous threads to use")
        if subcommand_name == "secrets":
            online_group = subcommand.add_mutually_exclusive_group()
            online_group.add_argument("--online", action="store_true", help="Access vaultwarden for tokens always")
            online_group.add_argument("--offline", action="store_true", help="Do not access vaultwarden for anything")
        group = subcommand.add_mutually_exclusive_group(required=True)
        group.add_argument("-d", "--dev", action="store_true", help="Dev mode")
        group.add_argument("-p", "--prod", action="store_true", help="Production mode")
    args = parser.parse_args(argv)

    applist = str(args.only).split(",") if args.only is not None else read_priority_apps_list()
    applist = [x.strip() for x in applist]
    applist = [path.basename(x) for x in applist]
    _applist = []
    for app in applist:
        if "*" in app:
            matched_apps = [x for x in docker_apps_list_all if re.match(app.replace("*", ".*").replace("-", "\\-"), x)]
            if args.only and len(matched_apps) == 0:
                print(f'App "{app}" not found', file=sys.stderr)
            elif len(matched_apps) == 0:
                assert False, f'Ap "{app}" not found'
            else:
                _applist.extend(matched_apps)
        else:
            if args.only and not path.exists(path.join(docker_apps_dir, app)):
                print(f'App "{app}" not found', file=sys.stderr)
            elif not path.exists(path.join(docker_apps_dir, app)):
                assert False, f'App "{app}" not found'
            else:
                _applist.append(app)
    applist = _applist

    command = args.subcommand
    force = args.force
    dryrun = args.dry_run
    is_online = (hasattr(args, "online") and args.online is True) or (not hasattr(args, "online") or args.offline is False)
    mode = "dev" if args.dev else "prod"

    if command == "install":
        server_install()

    if command in ["build", "deploy", "start", "stop", "secrets"]:
        server_docker_action(command)


def server_docker_action(action: str):
    action_log = action.capitalize() if action != "secrets" else "Secrets for"
    log.info("%s docker apps", action_log)

    docker_args = [f"--{mode}"]
    if dryrun:
        docker_args.append("--dry-run")
    if force:
        docker_args.append("--force")
    if action == "secrets":
        docker_args.append("--online" if is_online else "--offline")

    for app in applist:
        print(f"cwd: {path.join(server_dir, 'docker-apps', app)}")
        subprocess.check_call(["task", action, "--"] + docker_args, cwd=path.join(server_dir, "docker-apps", app))

    end_datetime = datetime.now()
    log.info("%s docker apps - SUCCESS on %s (%s)", action_log, end_datetime.strftime(r"%Y-%m-%d_%H-%M-%S"), re.sub(r".[0-9]+$", "", re.sub(r"^0:", "", str(end_datetime - start_datetime))))


def server_install():
    log.info("Installing global server config")

    subprocess.check_call(["sh", path.join(git_dir, ".utils", "deployment-helpers", "server-install.sh")])

    end_datetime = datetime.now()
    log.info("Installing global scripts - SUCCESS on %s (%s)", end_datetime.strftime(r"%Y-%m-%d_%H-%M-%S"), re.sub(r".[0-9]+$", "", re.sub(r"^0:", "", str(end_datetime - start_datetime))))


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except KeyboardInterrupt:
        sys.exit(1)
