#!/usr/bin/env python3

import argparse
import hashlib
import json
import logging
import os
import re
import subprocess
import sys
from datetime import datetime
from os import path
from typing import List

start_datetime = datetime.now()
start_datestr = os.environ["START_DATE"] if os.environ.get("START_DATE") is not None else start_datetime.strftime(r"%Y-%m-%d_%H-%M-%S")

app_dir = path.abspath(path.curdir)
git_dir = subprocess.check_output(["git", "rev-parse", "--show-toplevel"]).decode().strip()
full_app_name = path.basename(app_dir).lstrip(".")
log_file = path.join(git_dir, ".logs", start_datestr, "docker-apps", f"{full_app_name}.txt")

is_dryrun = False
is_online = True
is_pull = True
env_mode = ""
when_mode = ""

os.makedirs(path.dirname(log_file), exist_ok=True)

log = logging.getLogger()
log.setLevel(logging.INFO)
log.addHandler(logging.StreamHandler())
log.addHandler(logging.FileHandler(log_file))


def load_env_file(env_path):
    """
    Loads environment variables from a .env file into current environment
    """
    with open(env_path, "r") as file:
        for line in file:
            line = re.sub(r"#.*$", "", line).strip()
            if line == "":
                continue
            if os.environ.get(key) is not None:
                continue
            key, value = line.split("=", 1)
            os.environ[key] = value


def main(argv):
    global env_mode, is_dryrun, is_online, is_pull, when_mode  # pylint: disable=global-statement
    parser = argparse.ArgumentParser(prog="task")
    subparsers = parser.add_subparsers(dest="subcommand")
    subcommands = [
        subparsers.add_parser("build", help="Build this app"),
        subparsers.add_parser("secrets", help="Create secrets for this app"),
        subparsers.add_parser("deploy", help="Deploy app"),
        subparsers.add_parser("start", help="Start app"),
        subparsers.add_parser("stop", help="Stop app"),
    ]
    for subcommand in subcommands:
        subcommand_name = subcommand.prog.split(" ")[-1]
        subcommand.add_argument("--mode", type=str, choices=["dev", "prod"], help=f"Mode for {subcommand_name.capitalize()}. By default takes env variable HOMELAB_ENV")
        subcommand.add_argument("--dry-run", action="store_true", help="Dry run")
        if subcommand_name == "deploy":
            subcommand.add_argument("--when", type=str, choices=["always", "onchange"], default="always", help="Deploy app always, or only when it changed")
        if subcommand_name == "deploy" or subcommand_name == "build":
            subcommand.add_argument("--pull", action="store_true", help="Pull latest docker image from upstream registry")
        if subcommand_name == "secrets":
            online_group = subcommand.add_mutually_exclusive_group()
            online_group.add_argument("--online", action="store_true", help="Access vaultwarden for secrets")
            online_group.add_argument("--offline", action="store_true", help="Only generate secrets locally, do not access vaultwarden")

    args = parser.parse_args(argv)

    command = args.subcommand
    is_dryrun = args.dry_run

    if command == "deploy":
        when_mode = args.when
    if command == "secrets":
        is_online = (hasattr(args, "online") and args.online is True) or (not hasattr(args, "offline") or args.offline is False)
    is_pull = (hasattr(args, "pull") and args.pull is True)

    env_mode = args.mode
    if env_mode is None:
        env_mode = os.environ["HOMELAB_ENV"]
    if env_mode is None:
        print("Mode is unset, either pass in: `--mode dev|prod` or set env variable: `HOMELAB_ENV=dev|prod`")
    if env_mode not in ["dev", "prod"]:
        print(f"Invalid mode, got: {env_mode}, valid values are: dev|prod")
        sys.exit(1)

    if command not in ["build", "deploy", "start", "stop", "secrets"]:
        print(f"Unrecognized command: {command}")
        sys.exit(1)

    docker_compose_args = ["--file", "compose.yml", "--file", f"compose.{'prod' if env_mode == 'prod' else 'override'}.yml"]
    docker_command_args = []

    if is_dryrun:
        docker_command_args.append("--dry-run")

    default_env_values = {
        "DOCKER_COMPOSE_ENV": env_mode,
        "DOCKER_COMPOSE_CURRENT_USER": str(os.getuid()),
        "DOCKER_COMPOSE_APP_NAME": full_app_name,
        "DOCKER_COMPOSE_APP_TYPE": full_app_name,
        "DOCKER_COMPOSE_APP_PATH": app_dir,
        "DOCKER_COMPOSE_REPOROOT_PATH": git_dir,
        "DOCKER_COMPOSE_NETWORK_DOMAIN": f"{full_app_name}.matejhome.com" if env_mode == "prod" else "localhost",
        "DOCKER_COMPOSE_NETWORK_IP": "127.0.0.1",
        "DOCKER_COMPOSE_NETWORK_URL": f"https://{full_app_name}.matejhome.com" if env_mode == "prod" else "https://localhost:8443"
    }
    if default_env_values["DOCKER_COMPOSE_APP_TYPE"] == "samba":
        default_env_values["DOCKER_COMPOSE_NETWORK_URL"] = re.sub(r"https://", "smb://", default_env_values["DOCKER_COMPOSE_NETWORK_URL"])

    # Remove old OS environment
    for key in default_env_values.keys():
        if os.environ.get(key) is not None:
            os.environ.popitem(key)

    # Load env files
    if path.exists(path.join("config", "compose.env")):
        load_env_file(path.join("config", "compose.env"))
    if path.exists(path.join("config", f"compose-{env_mode}.env")):
        load_env_file(path.join("config", f"compose-{env_mode}.env"))

    # Fill in default values
    for key, default_value in default_env_values.items():
        if os.environ.get(key) is None:
            os.environ[key] = default_value

    # Check if docker-compose stack exists
    app_path = path.join(git_dir, "docker-compose", os.environ["DOCKER_COMPOSE_APP_TYPE"])
    if not path.isdir(app_path):
        print(f"Docker compose stack for app {os.environ['DOCKER_COMPOSE_APP_TYPE']} not found")
        sys.exit(1)

    docker_compose_args.extend(["--project-name", os.environ['DOCKER_COMPOSE_APP_NAME']])

    def docker_config() -> str:
        config_output = subprocess.check_output(["docker", "compose"] + docker_compose_args + ["config", "--format", "json"]).decode()
        config_obj = json.loads(config_output)
        image_names = sorted([config_obj["services"][service]["container_name"] for service in config_obj["services"]])
        output = []
        for image in image_names:
            inspect_output = subprocess.check_output(["docker", "image", "inspect", image, "--format", "json"]).decode()
            layers_output = subprocess.check_output(["jq", "-r", "(.[0].RootFS.Layers // [\"N/A\"])[]"], input=inspect_output.encode()).decode()
            sha = hashlib.sha1(layers_output.encode()).hexdigest()
            output.append(f"{image} {sha}")
        return "\n".join(output)

    def run(commands: List[str]):
        subprocess.check_call(commands)

    def docker_build():
        commands = ["docker", "compose"] + docker_compose_args + ["build", "--with-dependencies"] + docker_command_args + (["--pull"] if env_mode == "prod" else [])
        run(commands)

    def docker_stop():
        commands = ["docker", "compose"] + docker_compose_args + ["down"] + docker_command_args
        run(commands)

    def docker_start():
        commands = ["docker", "compose"] + docker_compose_args + ["up", "--force-recreate", "--always-recreate-deps", "--remove-orphans", "--no-build"] + docker_command_args + (["--detach", "--wait"] if env_mode == "prod" else [])
        run(commands)

    def create_secrets():
        commands = ["sh", f"{git_dir}/utils/secrets-helpers/main.sh", f"--{env_mode}", "--online" if is_online else "--offline"]
        run(commands)

    # Command dispatch
    if command == "build":
        docker_build()
    elif command == "deploy":
        config_before = docker_config()
        docker_build()
        config_after = docker_config()
        if when_mode == "always" or (when_mode == "onchange" and config_before != config_after):
            docker_stop()
            docker_start()
    elif command == "start":
        docker_start()
    elif command == "stop":
        docker_stop()
    elif command == "secrets":
        create_secrets()
    else:
        print(f"Unrecognized command '{command}'", file=sys.stderr)
        sys.exit(1)

    end_datetime = datetime.now()
    time_delta = (end_datetime - start_datetime).total_seconds()
    print()
    print(f"{command.capitalize()} of {full_app_name} successful in {int(time_delta) // 60:02d}:{int(time_delta) % 60:02d}.{int(time_delta * 100):02d}s")


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except KeyboardInterrupt:
        sys.exit(1)
