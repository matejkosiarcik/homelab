#!/usr/bin/env python3

import argparse
import datetime
import logging
import os
import re
import shutil
import subprocess
import sys
from os import path
from typing import List

start_date = datetime.datetime.now().strftime(r"%Y-%m-%d_%H-%M-%S")
os.environ["START_DATE"] = start_date

server_dir = path.abspath(path.curdir)
server_name = path.basename(server_dir)

log_dir = path.join(path.expanduser("~"), ".homelab-logs", start_date)
log_file = path.join(log_dir, "log.txt")
os.makedirs(log_dir, exist_ok=True)

docker_args = []
dryrun = False

log = logging.getLogger()
log.setLevel(logging.INFO)
log.addHandler(logging.StreamHandler())
log.addHandler(logging.FileHandler(log_file))


def read_priority_apps_list() -> List[str]:
    file = path.join(server_dir, "docker-apps", "priority.txt")
    with open(file, "r", encoding="utf-8") as file:
        lines = file.readlines()
    lines = [x.strip() for x in lines]
    lines = [re.sub(r"#.*$", "", x) for x in lines]
    lines = [x for x in lines if len(x) > 0]
    return lines


def main(argv: List[str]) -> int:
    global dryrun
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

    apps_list = str(args.only).split(",") if args.only is not None else read_priority_apps_list()
    for app in apps_list:
        if not path.exists(path.join(server_dir, "docker-apps", app)):
            raise FileNotFoundError(f'App "{app}" not found')

    command = args.subcommand
    force = args.force
    dryrun = args.dry_run
    mode = "dev" if args.dev else "prod"

    docker_args.append(f"--{mode}")
    if dryrun:
        docker_args.append("--dry-run")
    if force:
        docker_args.append("--force")

    if command == "build":
        server_build(apps_list)
    elif command == "create-secrets":
        server_create_secrets(apps_list)
    elif command == "deploy":
        server_install()
        server_deploy(apps_list)
    elif command == "install":
        server_install()
    elif command == "start":
        server_start(apps_list)
    elif command == "stop":
        server_stop(apps_list)


def server_build(applist: List[str]):
    log.info("Build docker apps in %", server_name)
    for app in applist:
        subprocess.check_call(["sh", path.join(server_dir, "docker-apps", app, "main.sh"), "build"] + docker_args)


def server_start(applist: List[str]):
    log.info("Start docker apps in %", server_name)
    for app in applist:
        subprocess.check_call(["sh", path.join(server_dir, "docker-apps", app, "main.sh"), "start"] + docker_args)


def server_stop(applist: List[str]):
    log.info("Stop docker apps in %", server_name)
    for app in applist:
        subprocess.check_call(["sh", path.join(server_dir, "docker-apps", app, "main.sh"), "stop"] + docker_args)


def server_deploy(applist: List[str]):
    log.info("Deploy docker apps in %", server_name)
    for app in applist:
        subprocess.check_call(["sh", path.join(server_dir, "docker-apps", app, "main.sh"), "deploy"] + docker_args)


def server_create_secrets(applist: List[str]):
    log.info("Init docker apps secrets in %", server_name)
    for app in applist:
        subprocess.check_call(["sh", path.join(server_dir, "docker-apps", app, "main.sh"), "create-secrets"] + docker_args)


def server_install():
    log.info("Installing global scripts in %", server_name)

    assert path.exists(path.join(server_dir, "startup.sh")), "Server startup.sh not found"
    if not dryrun:
        shutil.copy(path.join(server_dir, "startup.sh"), path.join(path.expanduser("~"), "startup.sh"))

    assert path.exists(path.join(server_dir, "crontab.cron")), "Server crontab.cron not found"
    if not dryrun:
        with open(path.join(server_dir, "crontab.cron"), encoding="utf-8") as file:
            subprocess.check_call(["crontab", "-"], stdin=file)


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except KeyboardInterrupt:
        sys.exit(1)
