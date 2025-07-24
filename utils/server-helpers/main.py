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
git_dir = subprocess.check_output(["git", "rev-parse", "--show-toplevel"]).decode().strip()
log_file = path.join(git_dir, ".logs", start_datestr, "server.txt")

os.makedirs(path.dirname(log_file), exist_ok=True)

applist = []
is_dryrun = False
is_online = True
is_pull = False
env_mode = ""
when_mode = ""

log = logging.getLogger()
log.setLevel(logging.INFO)
log.addHandler(logging.StreamHandler())
log.addHandler(logging.FileHandler(log_file))


def get_apps_list(only: str | None, skip: str | None) -> List[str]:
    all_apps_list = sorted([x for x in next(os.walk(path.join(server_dir, "docker-apps")))[1] if not x.startswith(".") and path.isdir(path.join(server_dir, "docker-apps", x))])

    with open(path.join(server_dir, "docker-apps", "priority.txt"), "r", encoding="utf-8") as file:
        priority_apps_list = [x for x in [re.sub(r"#.*$", "", x).strip() for x in file.readlines()] if len(x) > 0]

    def app_regex(appname: str) -> str:
        return f".*{appname.replace('?', '.').replace('*', '.*').replace('-', '\\-')}.*"

    output_apps_list = priority_apps_list

    if len(all_apps_list) != len(output_apps_list):
        extra_apps = ", ".join([x for x in all_apps_list if not x in output_apps_list])
        print(f"You have undeclared apps in priority.txt: {extra_apps}", file=sys.stderr)

    if only is not None and len(only) > 0:
        only_list = [x for x in only.split(",") if len(x) > 0]
        output_apps_list_2 = []
        for app in only_list:
            matched_apps = sorted([x for x in output_apps_list if re.match(app_regex(app), x)])
            output_apps_list_2.extend(matched_apps)
        output_apps_list = output_apps_list_2

    if skip is not None and len(skip) > 0:
        skip_list = [x for x in skip.split(",") if len(x) > 0]
        output_apps_list_2 = output_apps_list
        for app in skip_list:
            matched_apps = sorted([x for x in output_apps_list if re.match(app_regex(app), x)])
            for matched_app in matched_apps:
                output_apps_list_2.remove(matched_app)
        output_apps_list = output_apps_list_2

    return output_apps_list


def main(argv: List[str]):
    global applist, env_mode, is_dryrun, is_online, is_pull, when_mode  # pylint: disable=global-statement
    parser = argparse.ArgumentParser(prog="task")
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
        subcommand.add_argument("--mode", type=str, choices=["dev", "prod"], help=f"Mode for {subcommand_name.capitalize()}. By default takes env variable HOMELAB_ENV")
        subcommand.add_argument("--dry-run", action="store_true", help="Dry run")
        # TODO: Maybe multiarg --only and --skip???
        subcommand.add_argument("--only", type=str, help=f"{subcommand_name.capitalize()} only these apps")
        subcommand.add_argument("--skip", type=str, help=f"{subcommand_name.capitalize()} all apps except these")
        subcommand.add_argument("--jobs", type=int, default=1, help="A number of simultaneous actions to perform")
        if subcommand_name == "deploy":
            subcommand.add_argument("--when", type=str, choices=["always", "onchange"], default="always", help="Deploy all apps always, or only when they changed")
        if subcommand_name in ["deploy", "build"]:
            subcommand.add_argument("--pull", action="store_true", help="Pull latest docker image from upstream registry")
        if subcommand_name == "secrets":
            online_group = subcommand.add_mutually_exclusive_group()
            online_group.add_argument("--online", action="store_true", help="Access vaultwarden for secrets")
            online_group.add_argument("--offline", action="store_true", help="Only generate secrets locally, do not access vaultwarden")

    args = parser.parse_args(argv)

    applist = get_apps_list(args.only, args.skip)

    command = args.subcommand
    is_dryrun = args.dry_run

    if command == "secrets":
        is_online = (hasattr(args, "online") and args.online is True) or (not hasattr(args, "offline") or args.offline is False)
    if command == "deploy":
        when_mode = args.when

    is_pull = (hasattr(args, "pull") and args.pull is True)

    env_mode = args.mode
    if env_mode is None:
        env_mode = os.environ["HOMELAB_ENV"]
    if env_mode is None:
        print("Mode is unset, either pass in: `--mode dev|prod` or set env variable: `HOMELAB_ENV=dev|prod`")
    if env_mode not in ["dev", "prod"]:
        print(f"Invalid mode, got: {env_mode}, valid values are: dev|prod")
        sys.exit(1)

    if command == "install":
        server_install()
        return

    if command in ["build", "deploy", "start", "stop", "secrets"]:
        server_action(command)
        return

    print(f"Unrecognized command: {command}")
    sys.exit(1)


def server_action(action: str):
    action_log = "Secrets for" if action == "secrets" else action.capitalize()
    log.info("%s docker apps", action_log)

    cli_args = ["--mode", env_mode]
    if is_dryrun:
        cli_args.append("--dry-run")
    if is_pull:
        cli_args.append("--pull")
    if action == "secrets":
        cli_args.append("--online" if is_online else "--offline")
    if action == "deploy":
        cli_args.append("--deploy", when_mode)

    for app in applist:
        subprocess.check_call(["task", action, "--"] + cli_args, cwd=path.join(server_dir, "docker-apps", app))

    end_datetime = datetime.now()
    log.info("%s docker apps - SUCCESS on %s (%s)", action_log, end_datetime.strftime(r"%Y-%m-%d_%H-%M-%S"), re.sub(r".[0-9]+$", "", re.sub(r"^0:", "", str(end_datetime - start_datetime))))


def server_install():
    log.info("Installing global server config")
    subprocess.check_call(["sh", path.join(git_dir, "utils", "servers-helpers", "install.sh")])
    end_datetime = datetime.now()
    log.info("Installing global scripts - SUCCESS on %s (%s)", end_datetime.strftime(r"%Y-%m-%d_%H-%M-%S"), re.sub(r".[0-9]+$", "", re.sub(r"^0:", "", str(end_datetime - start_datetime))))


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except KeyboardInterrupt:
        sys.exit(0)
