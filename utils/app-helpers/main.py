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

docker_compose_args = []
docker_command_args = []

os.makedirs(path.dirname(log_file), exist_ok=True)

log = logging.getLogger()
log.setLevel(logging.INFO)
log.addHandler(logging.StreamHandler())
log.addHandler(logging.FileHandler(log_file))


def load_env_file(env_path):
    """
    Loads environment variables from a .env file into current environment
    """
    with open(env_path, "r", encoding="utf-8") as file:
        for line in file:
            line = re.sub(r"#.*$", "", line).strip()
            if line == "":
                continue
            key, value = line.split("=", 1)
            if os.environ.get(key) is not None:
                continue
            os.environ[key] = value


def load_full_env():
    default_env_values = {
        "DOCKER_COMPOSE_APP_NAME": full_app_name,
        "DOCKER_COMPOSE_APP_PATH": app_dir,
        "DOCKER_COMPOSE_APP_TYPE": full_app_name,
        "DOCKER_COMPOSE_CURRENT_USER": str(os.getuid()),
        "DOCKER_COMPOSE_ENV": env_mode,
        "DOCKER_COMPOSE_NETWORK_DOMAIN": f"{full_app_name}.matejhome.com" if env_mode == "prod" else "localhost",
        "DOCKER_COMPOSE_NETWORK_IP": "127.0.0.1",
        "DOCKER_COMPOSE_NETWORK_URL": f"https://{full_app_name}.matejhome.com" if env_mode == "prod" else "https://localhost:8443",
        "DOCKER_COMPOSE_REPOROOT_PATH": git_dir,
    }
    if default_env_values["DOCKER_COMPOSE_APP_TYPE"] == "samba":
        default_env_values["DOCKER_COMPOSE_NETWORK_URL"] = re.sub(r"https://", "smb://", default_env_values["DOCKER_COMPOSE_NETWORK_URL"])

    # Remove old environment values
    for key in default_env_values:
        if os.environ.get(key) is not None:
            os.environ.pop(key)

    # Load env files
    if path.exists(path.join("config", "compose.env")):
        load_env_file(path.join("config", "compose.env"))
    if path.exists(path.join("config", f"compose-{env_mode}.env")):
        load_env_file(path.join("config", f"compose-{env_mode}.env"))

    # Fill in default values
    for key, default_value in default_env_values.items():
        if os.environ.get(key) is None:
            os.environ[key] = default_value


def get_docker_compose_config() -> str:
    return subprocess.check_output(["docker", "compose"] + docker_compose_args + ["config", "--format", "json"]).decode()


def get_docker_images_shasum(config: str) -> str:
    config_obj = json.loads(config)
    image_names = sorted([config_obj["services"][service]["container_name"] for service in config_obj["services"]])
    output = []
    for image in image_names:
        try:
            inspect_output = subprocess.check_output(["docker", "image", "inspect", image, "--format", "json"], stderr=subprocess.DEVNULL).decode()
            layers_output = subprocess.check_output(["jq", "-r", '(.[0].RootFS.Layers // ["N/A"])[]'], input=inspect_output.encode()).decode().replace("\n", " ").strip()
        except subprocess.CalledProcessError:
            layers_output = "N/A"
        sha = hashlib.sha1(layers_output.encode()).hexdigest()
        output.append(f"{image} {sha}")
    return "\n".join(output)


def docker_build():
    commands = ["docker", "compose"] + docker_compose_args + ["--parallel", "1", "build", "--with-dependencies"] + docker_command_args + (["--pull"] if is_pull else [])
    subprocess.check_call(commands)


def docker_stop():
    commands = ["docker", "compose"] + docker_compose_args + ["down"] + docker_command_args
    subprocess.check_call(commands)


def docker_start():
    commands = ["docker", "compose"] + docker_compose_args + ["up", "--force-recreate", "--always-recreate-deps", "--remove-orphans", "--no-build"] + docker_command_args + (["--detach", "--wait"] if env_mode == "prod" else [])
    subprocess.check_call(commands)


def create_secrets():
    if os.environ.get("HOMELAB_SECRETS_PREPARED") != "yes":
        precommands = ["sh", f"{git_dir}/utils/secrets-helpers/prepare.sh", f"--{env_mode}", "--online" if is_online else "--offline"]
        subprocess.check_call(precommands)
    commands = ["sh", f"{git_dir}/utils/secrets-helpers/main.sh", f"--{env_mode}", "--online" if is_online else "--offline"]
    subprocess.check_call(commands)


def run_main_command(command: str):
    global docker_compose_args, docker_command_args  # pylint: disable=global-statement
    docker_compose_args = ["--file", "compose.yml", "--file", f"compose.{'prod' if env_mode == 'prod' else 'override'}.yml", "--project-name", os.environ["DOCKER_COMPOSE_APP_NAME"]]
    docker_command_args = ["--dry-run"] if is_dryrun else []

    # Check if docker-compose stack exists
    compose_path = path.join(git_dir, "docker-compose", os.environ["DOCKER_COMPOSE_APP_TYPE"])
    if not path.isdir(compose_path):
        print(f"Docker compose stack for app {os.environ['DOCKER_COMPOSE_APP_TYPE']} not found")
        sys.exit(1)

    print(f"Starting {command} of {full_app_name}")

    # Execute commands
    if command == "build":
        docker_build()
    elif command == "deploy":
        config = get_docker_compose_config()
        shasum_before = get_docker_images_shasum(config)
        docker_build()
        shasum_after = get_docker_images_shasum(config)
        if when_mode == "always" or (when_mode == "onchange" and shasum_before != shasum_after):
            docker_stop()
            docker_start()
    elif command == "restart":
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
    print(f"{command.capitalize()} of {full_app_name} successful in {int(time_delta) // 60:02d}:{int(time_delta) % 60:02d}.{int((time_delta % 1) * 10):d}s")


def main(argv):
    global env_mode, is_dryrun, is_online, is_pull, when_mode  # pylint: disable=global-statement
    parser = argparse.ArgumentParser(prog="task")
    subparsers = parser.add_subparsers(dest="subcommand")
    subcommands = [
        subparsers.add_parser("build", help="Build this app"),
        subparsers.add_parser("deploy", help="Deploy app (build + stop + start)"),
        subparsers.add_parser("restart", help="Restart app (stop + start)"),
        subparsers.add_parser("secrets", help="Create secrets for this app"),
        subparsers.add_parser("start", help="Start app"),
        subparsers.add_parser("stop", help="Stop app"),
    ]
    for subcommand in subcommands:
        subcommand_name = subcommand.prog.split(" ")[-1]
        subcommand.add_argument("--mode", type=str, choices=["dev", "prod"], help=f"Mode for {subcommand_name.capitalize()}. By default takes env variable HOMELAB_ENV")
        subcommand.add_argument("--dry-run", action="store_true", help="Dry run")
        if subcommand_name == "deploy":
            deploy_when_group = subcommand.add_mutually_exclusive_group()
            deploy_when_group.add_argument("--onchange", action="store_true", help="Deploy app only when build changed. When there is no change, app is not restarted.")
            deploy_when_group.add_argument("--always", action="store_true", help="Deploy app always, regardless if the build changed or not.")
        if subcommand_name in ["deploy", "build"]:
            subcommand.add_argument("--pull", action="store_true", help="Pull latest docker image from upstream registry")
        if subcommand_name == "secrets":
            online_group = subcommand.add_mutually_exclusive_group()
            online_group.add_argument("--online", action="store_true", help="Access vaultwarden for secrets")
            online_group.add_argument("--offline", action="store_true", help="Only generate secrets locally, do not access vaultwarden")

    args = parser.parse_args(argv)

    command = args.subcommand
    is_dryrun = args.dry_run

    if command == "deploy":
        when_mode = "onchange" if (hasattr(args, "onchange") and args.onchange is True) else "always" if (hasattr(args, "always") and args.always is True) else "always"
    if command == "secrets":
        is_online = (hasattr(args, "online") and args.online is True) or (not hasattr(args, "offline") or args.offline is False)
    is_pull = hasattr(args, "pull") and args.pull is True

    env_mode = args.mode
    if env_mode is None:
        env_mode = os.environ["HOMELAB_ENV"]
    if env_mode is None:
        print("Mode is unset, either pass in: `--mode dev|prod` or set env variable: `HOMELAB_ENV=dev|prod`")
    if env_mode not in ["dev", "prod"]:
        print(f"Invalid mode, got: {env_mode}, valid values are: dev|prod")
        sys.exit(1)

    if command not in ["build", "deploy", "restart", "secrets", "start", "stop"]:
        print(f"Unrecognized command: {command}")
        sys.exit(1)

    load_full_env()
    run_main_command(command)


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except KeyboardInterrupt:
        sys.exit(0)
