#!/usr/bin/env python3

import argparse
import logging
import os
import pathlib
import re
import subprocess
import sys
import time
from datetime import datetime
from os import path

local_tz = datetime.now().astimezone().tzinfo
start_datetime = datetime.now(local_tz)
start_datestr = start_datetime.strftime(r"%Y-%m-%d_%H-%M-%S")
start_time = start_datetime.timestamp()
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
include_secrets = False

log = logging.getLogger()
log.setLevel(logging.INFO)
log.addHandler(logging.StreamHandler())
log.addHandler(logging.FileHandler(log_file))


def tty_supports_color():
    return sys.stdout.isatty() and os.environ.get("TERM") not in (None, "", "dumb")


ascii_checkmark = "✔"
ascii_cross = "✘"
if tty_supports_color():
    ascii_checkmark = f"\033[32m{ascii_checkmark}\033[0m"
    ascii_cross = f"\033[31m{ascii_cross}\033[0m"


def get_apps_list(only_apps: str | None, skip_apps: str | None) -> list[str]:
    apps_list_output = []

    priority_file = path.join(server_dir, "docker-apps", "priority.txt")
    if path.exists(priority_file):
        with open(priority_file, "r", encoding="utf-8") as file:
            apps_list_output += [app for app in [re.sub(r"#.*$", "", line).strip() for line in file] if len(app) > 0]

    for item in sorted(pathlib.Path(path.join(server_dir, "docker-apps")).iterdir()):
        if item.is_dir() and not item.name.startswith(".") and item.name not in apps_list_output:
            apps_list_output.append(item.name)

    def app_regex(appname: str) -> str:
        partial_regex = appname.replace("?", ".").replace("*", ".*").replace("-", "\\-")
        return f".*{partial_regex}.*"

    if only_apps is not None and len(only_apps) > 0:
        args_only_list = [x for x in only_apps.split(",") if len(x) > 0]
        apps_list_filtered = []
        for app in args_only_list:
            matched_apps = sorted([x for x in apps_list_output if re.match(app_regex(app), x)])
            apps_list_filtered.extend(matched_apps)
        apps_list_output = apps_list_filtered

    if skip_apps is not None and len(skip_apps) > 0:
        args_skip_list = [x for x in skip_apps.split(",") if len(x) > 0]
        apps_list_filtered = apps_list_output
        for app in args_skip_list:
            matched_apps = sorted([x for x in apps_list_output if re.match(app_regex(app), x)])
            for matched_app in matched_apps:
                apps_list_filtered.remove(matched_app)
        apps_list_output = apps_list_filtered

    return apps_list_output


def main(argv: list[str]):
    global applist, env_mode, include_secrets, is_dryrun, is_online, is_pull, when_mode  # pylint: disable=global-statement
    parser = argparse.ArgumentParser(prog="task")
    subparsers = parser.add_subparsers(dest="subcommand")
    subcommands = [
        subparsers.add_parser("build", help="Build docker images for all docker apps"),
        subparsers.add_parser("deploy", help="Deploy all docker apps (build + stop + start)"),
        subparsers.add_parser("install", help="Install main server scripts"),
        subparsers.add_parser("restart", help="Restart all docker apps (stop + start)"),
        subparsers.add_parser("secrets", help="Create secrets for all docker apps"),
        subparsers.add_parser("start", help="Start all docker apps"),
        subparsers.add_parser("stop", help="Stop all docker apps"),
    ]
    for subcommand in subcommands:
        subcommand_name = subcommand.prog.split(" ")[-1]
        subcommand.add_argument("--mode", type=str, choices=["dev", "prod"], help=f"Mode for {subcommand_name.capitalize()}. By default takes env variable HOMELAB_ENV")
        subcommand.add_argument("--dry-run", action="store_true", help="Dry run")
        subcommand.add_argument("--only", type=str, help=f"{subcommand_name.capitalize()} only these apps")
        subcommand.add_argument("--skip", type=str, help=f"{subcommand_name.capitalize()} all apps except these")
        subcommand.add_argument("--jobs", type=int, default=1, help="A number of simultaneous actions to perform")
        if subcommand_name == "deploy":
            deploy_when_group = subcommand.add_mutually_exclusive_group()
            deploy_when_group.add_argument("--onchange", action="store_true", help="Deploy apps only when build changed. When there is no change, app is not restarted.")
            deploy_when_group.add_argument("--always", action="store_true", help="Deploy apps always, regardless if the build changed or not.")
            subcommand.add_argument("--with-secrets", action="store_true", help="Also regenerate secrets")
        if subcommand_name in ["deploy", "build"]:
            subcommand.add_argument("--pull", action="store_true", help="Pull latest docker image from upstream registry")

    args = parser.parse_args(argv)

    command = args.subcommand
    is_dryrun = args.dry_run

    applist = get_apps_list(args.only, args.skip)

    if command == "secrets":
        is_online = (hasattr(args, "online") and args.online is True) or (not hasattr(args, "offline") or args.offline is False)
    if command == "deploy":
        when_mode = "onchange" if (hasattr(args, "onchange") and args.onchange is True) else "always"
        include_secrets = hasattr(args, "with_secrets") and args.with_secrets is True

    is_pull = hasattr(args, "pull") and args.pull is True

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

    if command in ["build", "deploy", "restart", "secrets", "start", "stop"]:
        server_action(command)
        return

    print(f"Unrecognized command: {command}")
    sys.exit(1)


def server_action(action: str):
    action_log = "Secrets for" if action == "secrets" else action.capitalize()
    print(f"↓ {action_log} docker apps")
    print("\n---\n")

    cli_args = ["--mode", env_mode]
    if is_dryrun:
        cli_args.append("--dry-run")
    if is_pull:
        cli_args.append("--pull")
    if action == "deploy" and include_secrets is True:
        cli_args.append("--with-secrets")
    if action == "deploy":
        cli_args.extend([f"--{when_mode}"])

    for app in applist:
        subprocess.check_call(["task", action, "--"] + cli_args, cwd=path.join(server_dir, "docker-apps", app))
        print("\n---\n")

    total_elapsed = time.time() - start_time
    total_elapsed_mins = int(total_elapsed) // 60
    total_elapsed_secs = int(total_elapsed) % 60
    print(f"{ascii_checkmark} {action_log} docker apps {total_elapsed_mins:02d}:{total_elapsed_secs:02d}")


def server_install():
    print("↓ Installing global server config")
    subprocess.check_call(["sh", path.join(git_dir, "utils", "server-helpers", "install.sh")])
    total_elapsed = time.time() - start_time
    total_elapsed_mins = int(total_elapsed) // 60
    total_elapsed_secs = int(total_elapsed) % 60
    print(f"{ascii_checkmark} Install global config {total_elapsed_mins:02d}:{total_elapsed_secs:02d}")


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except KeyboardInterrupt:
        sys.exit(0)
