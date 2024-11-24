#!/usr/bin/env python3

import argparse
import logging
import os
import re
import shutil
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

log_dir = path.join(path.expanduser("~"), ".homelab-logs", start_datestr)
log_file = path.join(log_dir, "log.txt")
os.makedirs(log_dir, exist_ok=True)

docker_args = []
dryrun = False
applist = []

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
    global applist, dryrun  # pylint: disable=global-statement
    parser = argparse.ArgumentParser(prog="main.sh")
    subparsers = parser.add_subparsers(dest="subcommand")
    subcommands = [
        subparsers.add_parser("build", help="Build docker images for all docker apps"),
        subparsers.add_parser("create-secrets", help="Create secrets for all docker apps"),
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
        group = subcommand.add_mutually_exclusive_group(required=True)
        group.add_argument("-d", "--dev", action="store_true", help="Dev mode")
        group.add_argument("-p", "--prod", action="store_true", help="Production mode")
    args = parser.parse_args(argv)

    applist = str(args.only).split(",") if args.only is not None else read_priority_apps_list()
    for app in applist:
        assert path.exists(path.join(server_dir, "docker-apps", app)), f'App "{app}" not found'

    command = args.subcommand
    force = args.force
    dryrun = args.dry_run
    mode = "dev" if args.dev else "prod"

    docker_args.append(f"--{mode}")
    if dryrun:
        docker_args.append("--dry-run")
    if force:
        docker_args.append("--force")

    if command in ["deploy", "install"]:
        server_install()

    if command in ["build", "create-secrets", "deploy", "start", "stop"]:
        server_docker_action(command)


def server_docker_action(action: str):
    action_log = action.capitalize() if action != "create-secrets" else "Create-secrets for"
    log.info("%s docker apps", action_log)

    for app in applist:
        subprocess.check_call(["sh", path.join(server_dir, "docker-apps", app, "main.sh"), action] + docker_args)

    end_datetime = datetime.now()
    log.info("%s docker apps - SUCCESS on %s (%s)", action_log, end_datetime.strftime(r"%Y-%m-%d_%H-%M-%S"), re.sub(r".[0-9]+$", "", re.sub(r"^0:", "", str(end_datetime - start_datetime))))


def server_install():
    log.info("Installing global scripts")

    assert path.exists(path.join(server_dir, "startup.sh")), "Server startup.sh not found"
    if not dryrun:
        shutil.copy(path.join(server_dir, "startup.sh"), path.join(path.expanduser("~"), "startup.sh"))

    assert path.exists(path.join(server_dir, "crontab.cron")), "Server crontab.cron not found"
    if not dryrun:
        with open(path.join(server_dir, "crontab.cron"), encoding="utf-8") as file:
            subprocess.check_call(["crontab", "-"], stdin=file)

    end_datetime = datetime.now()
    log.info("Installing global scripts - SUCCESS on %s (%s)", end_datetime.strftime(r"%Y-%m-%d_%H-%M-%S"), re.sub(r".[0-9]+$", "", re.sub(r"^0:", "", str(end_datetime - start_datetime))))


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except KeyboardInterrupt:
        sys.exit(1)