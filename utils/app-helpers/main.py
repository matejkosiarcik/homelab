#!/usr/bin/env python3

import argparse
import collections
import hashlib
import json
import logging
import math
import os
import pty
import re
import shutil
import subprocess
import sys
import threading
import time
from datetime import datetime
from os import path
from typing import List

start_datestr = os.environ["START_DATE"] if os.environ.get("START_DATE") is not None else datetime.now().strftime(r"%Y-%m-%d_%H-%M-%S")

app_dir = path.abspath(path.curdir)
git_dir = subprocess.check_output(["git", "rev-parse", "--show-toplevel"]).decode().strip()
full_app_name = path.basename(app_dir).lstrip(".")
app_type = full_app_name
if path.exists(path.join(app_dir, "config", "app.txt")):
    with open(path.join(app_dir, "config", "app.txt"), "r", encoding="utf-8") as appfile:
        app_type = appfile.read().strip()
global_log_filepath = path.join(app_dir, "app-logs", ".meta", "main.log")

is_dryrun = False
is_online = True
is_pull = True
env_mode = ""
when_mode = ""
include_secrets = False

docker_compose_args = []
docker_command_args = []

# Ensure logfile exists and is empty
if path.exists(path.dirname(global_log_filepath)):
    shutil.rmtree(path.dirname(global_log_filepath))
os.makedirs(path.dirname(global_log_filepath), exist_ok=True)
with open(global_log_filepath, "w", encoding="utf-8") as global_log_file:
    pass

log = logging.getLogger()
log.setLevel(logging.INFO)
log.addHandler(logging.StreamHandler())
log.addHandler(logging.FileHandler(global_log_filepath))


# Write current anticache.txt
with open(
    path.join(git_dir, "docker-images", ".shared", "anticache.txt"),
    "w",
    encoding="utf-8",
) as anticachefile:
    print(
        f"This file is for cache busting\nDatetime: {datetime.now().isoformat()}\n",
        file=anticachefile,
    )


def tty_supports_color():
    return sys.stdout.isatty() and os.environ.get("TERM") not in (None, "", "dumb")


ascii_checkmark = "✔"
ascii_cross = "✘"
if tty_supports_color():
    ascii_checkmark = f"\033[32m{ascii_checkmark}\033[0m"
    ascii_cross = f"\033[31m{ascii_cross}\033[0m"


last_exit_code: int | None = None


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
    default_protocol = "smb" if "samba" in full_app_name else "https"
    default_env_values = {
        "DOCKER_COMPOSE_APP_NAME": full_app_name,
        "DOCKER_COMPOSE_APP_PATH": app_dir,
        "DOCKER_COMPOSE_APP_TYPE": app_type,
        "DOCKER_COMPOSE_ENV": env_mode,
        "DOCKER_COMPOSE_NETWORK_DOMAIN": f"{full_app_name}.matejhome.com" if env_mode == "prod" else "localhost",
        "DOCKER_COMPOSE_NETWORK_IP": "127.0.0.1",
        "DOCKER_COMPOSE_NETWORK_URL": f"{default_protocol}://{full_app_name}.matejhome.com" if env_mode == "prod" else f"{default_protocol}://localhost:8443",
        "DOCKER_COMPOSE_REPOROOT_PATH": git_dir,
        "DOCKER_COMPOSE_UID": str(os.getuid()) if env_mode == "prod" else "1000",
        "DOCKER_COMPOSE_GID": str(os.getgid()) if env_mode == "prod" else "1000",
    }

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

    for i in range(2, 10):
        if os.environ.get(f"DOCKER_COMPOSE_NETWORK_DOMAIN_{i}") is not None and os.environ.get(f"DOCKER_COMPOSE_NETWORK_URL_{i}") is None:
            domain = os.environ[f"DOCKER_COMPOSE_NETWORK_DOMAIN_{i}"]
            os.environ[f"DOCKER_COMPOSE_NETWORK_URL_{i}"] = f"{default_protocol}://{domain}"
        elif os.environ.get(f"DOCKER_COMPOSE_NETWORK_URL_{i}") is None:
            domain = os.environ["DOCKER_COMPOSE_NETWORK_DOMAIN"]
            os.environ[f"DOCKER_COMPOSE_NETWORK_URL_{i}"] = f"{default_protocol}://{domain}"
            os.environ[f"DOCKER_COMPOSE_NETWORK_DOMAIN_{i}"] = domain


def symlink_app():
    compose_dir = path.join(git_dir, "docker-compose", app_type)
    for file in ["compose.yml", "compose.override.yml", "compose.prod.yml"]:
        try:
            os.remove(file)
        except OSError:
            pass
    os.symlink(path.join(compose_dir, "compose.yml"), "compose.yml")
    os.symlink(path.join(compose_dir, "compose.override-dev.yml"), "compose.override.yml")
    os.symlink(path.join(compose_dir, "compose.override-prod.yml"), "compose.prod.yml")


def get_docker_compose_config() -> str:
    return subprocess.check_output(["docker", "compose"] + docker_compose_args + ["config", "--format", "json"]).decode()


def get_docker_images_shasum(config: str) -> str:
    config_obj = json.loads(config)
    image_names = sorted([config_obj["services"][service]["image"] for service in config_obj["services"]])
    output = []
    for image in image_names:
        try:
            inspect_output = subprocess.check_output(
                ["docker", "image", "inspect", image, "--format", "json"],
                stderr=subprocess.DEVNULL,
            ).decode()
            layers_output = (
                subprocess.check_output(
                    ["jq", "-r", '(.[0].RootFS.Layers // ["N/A"])[]'],
                    input=inspect_output.encode(),
                )
                .decode()
                .replace("\n", " ")
                .strip()
            )
        except subprocess.CalledProcessError:
            layers_output = "N/A"
        sha = hashlib.sha1(layers_output.encode()).hexdigest()
        output.append(f"{image} {sha}")
    return "\n".join(output)


# pylint: disable=too-many-locals
def run_with_spinner(
    command: List[str],
    description_progress: str,
    description_done: str,
    command_log_file: str,
    print_output: bool,
):
    start_time = time.time()
    done = threading.Event()
    global_exit = False
    last_output_line = ""

    def subprocess_main():
        global last_exit_code  # pylint: disable=global-statement
        last_exit_code = None
        master_fd, slave_fd = pty.openpty()  # This is for making the subprocess think the output is a TTY and it enables colored output
        with open(command_log_file, "a", encoding="utf-8") as file:
            with subprocess.Popen(
                command,
                stdout=slave_fd,
                stderr=slave_fd,
                stdin=slave_fd,
                text=True,
                bufsize=1,
                close_fds=True,
            ) as last_process:
                os.close(slave_fd)
                while True:
                    try:
                        output = os.read(master_fd, 1024).decode("utf-8", errors="replace")
                        if not output or len(output) == 0:
                            break
                        file.write(re.sub(r"\x1B(?:[@-Z\-_]|\[[0-?]*[ -/]*[@-~])", "", output))
                        file.flush()
                        if print_output and not global_exit:
                            sys.stdout.write(output)
                    except OSError:
                        break
                    if done.is_set():
                        last_process.kill()
                last_exit_code = last_process.wait()
                done.set()

    try:
        subprocess_thread = threading.Thread(target=subprocess_main)
        subprocess_thread.start()

        spinner_chars = "▖▘▝▗"
        spinner_index = 0

        if print_output:
            print(f"↓ {description_progress} {os.environ['DOCKER_COMPOSE_APP_NAME']} 00:00")

        while not done.is_set():
            elapsed = time.time() - start_time
            elapsed_mins = int(elapsed) // 60
            elapsed_secs = int(elapsed) % 60
            last_output_line = f"{spinner_chars[math.floor(spinner_index)]} {description_progress} {os.environ['DOCKER_COMPOSE_APP_NAME']} {elapsed_mins:02d}:{elapsed_secs:02d} "
            if global_exit:
                break
            if not print_output:
                print(f"\r{last_output_line}", end="", flush=True)
            spinner_index += 1
            spinner_index %= len(spinner_chars)
            done.wait(0.1)

        subprocess_thread.join()
    except KeyboardInterrupt:
        global_exit = True
        done.set()
    finally:
        done.set()
        total_elapsed = time.time() - start_time
        total_elapsed_mins = int(total_elapsed) // 60
        total_elapsed_secs = int(total_elapsed) % 60
        status_marker = ascii_checkmark if last_exit_code == 0 and not global_exit else ascii_cross
        print(f"\r{' ' * len(last_output_line)}", end="", flush=True)
        print(
            f"\r{status_marker} {description_done} {os.environ['DOCKER_COMPOSE_APP_NAME']} {total_elapsed_mins:02d}:{total_elapsed_secs:02d} ",
            file=sys.stderr,
        )

        if last_exit_code != 0 and not global_exit:
            log.error("Process exit code: %s", last_exit_code)
            log.error("Process args: %s", " ".join(command))
            log.error("Process output:")
            with open(command_log_file, "r", encoding="utf-8") as file:
                for line in collections.deque(file, maxlen=30):
                    log.error(">> %s", line.rstrip())
            log.error('See logfile "%s" for all details.', path.basename(command_log_file))
            sys.exit(1)

    if global_exit:
        sys.exit(0)


def docker_build():
    cpu_cores = os.cpu_count()
    if cpu_cores is None:
        cpu_cores = 1
    threads = math.ceil(cpu_cores // 2)
    commands = ["docker", "compose"] + docker_compose_args + ["--parallel", f"{threads}", "build", "--with-dependencies", "--provenance=false"] + docker_command_args + (["--pull"] if is_pull else [])
    docker_log_file = path.join(
        "app-logs",
        ".meta",
        f"{datetime.now().strftime(r'%Y-%m-%d_%H-%M-%S')} - docker-build.log",
    )
    run_with_spinner(commands, "Building", "Build", docker_log_file, False)


def docker_stop():
    commands = ["docker", "compose"] + docker_compose_args + ["down"] + docker_command_args
    docker_log_file = path.join(
        "app-logs",
        ".meta",
        f"{datetime.now().strftime(r'%Y-%m-%d_%H-%M-%S')} - docker-stop.log",
    )
    run_with_spinner(commands, "Stopping", "Stop", docker_log_file, False)


def docker_start():
    config_json = get_docker_compose_config()
    config_obj = json.loads(config_json)

    # Extract all volumes from docker-compose yaml
    volumes: List[str] = []
    for service in config_obj["services"]:
        if "volumes" not in config_obj["services"][service]:
            continue
        for volume in config_obj["services"][service]["volumes"]:
            volumes.append(volume["source"])

    # Precreate all volumes - this ensures proper directory permissions
    for volume in volumes:
        created = False
        if not path.exists(volume):
            os.makedirs(volume, exist_ok=True)
            created = True
            os.chmod(volume, mode=0o755)  # TODO: Remove this line and uncomment code below
        if created or volume.startswith(app_dir):
            pass  # TODO: Re-enable code below
            # os.chown(volume, uid=current_user, gid=current_user_group)
            # os.chmod(volume, mode=0o755)  # TODO: Change to 0o750

    commands = ["docker", "compose"] + docker_compose_args + ["up", "--force-recreate", "--always-recreate-deps", "--remove-orphans", "--no-build"] + docker_command_args + (["--detach", "--wait"] if env_mode == "prod" else [])
    docker_log_file = path.join(
        "app-logs",
        ".meta",
        f"{datetime.now().strftime(r'%Y-%m-%d_%H-%M-%S')} - docker-start.log",
    )
    run_with_spinner(commands, "Starting", "Start", docker_log_file, env_mode == "dev")


def create_secrets():
    docker_log_file = path.join("app-logs", ".meta", f"{datetime.now().strftime(r'%Y-%m-%d_%H-%M-%S')} - secrets.log")
    if os.environ.get("HOMELAB_SECRETS_PREPARED") != "yes":
        precommands = [
            "sh",
            f"{git_dir}/utils/secrets-helpers/prepare.sh",
            f"--{env_mode}",
            "--online" if is_online else "--offline",
        ]
        run_with_spinner(precommands, "Preparing secrets", "Prepare secrets", docker_log_file, False)
    commands = [
        "sh",
        f"{git_dir}/utils/secrets-helpers/main.sh",
        f"--{env_mode}",
        "--online" if is_online else "--offline",
    ]
    run_with_spinner(commands, "Secrets", "Secrets", docker_log_file, False)


def run_main_command(command: str):
    global docker_compose_args, docker_command_args  # pylint: disable=global-statement
    docker_compose_args = [
        "--file",
        "compose.yml",
        "--file",
        f"compose.{'prod' if env_mode == 'prod' else 'override'}.yml",
        "--project-name",
        os.environ["DOCKER_COMPOSE_APP_NAME"],
        "--progress",
        "plain",
    ]
    docker_command_args = ["--dry-run"] if is_dryrun else []

    # Check if docker-compose stack exists
    compose_path = path.join(git_dir, "docker-compose", os.environ["DOCKER_COMPOSE_APP_TYPE"])
    if not path.isdir(compose_path):
        print(f"Docker compose stack for app {os.environ['DOCKER_COMPOSE_APP_TYPE']} not found")
        sys.exit(1)

    # Execute commands
    if command == "build":
        docker_build()
    elif command == "deploy":
        if include_secrets is True:
            create_secrets()
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


def main(argv):
    global env_mode, include_secrets, is_dryrun, is_online, is_pull, when_mode  # pylint: disable=global-statement
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
        subcommand.add_argument(
            "--mode",
            type=str,
            choices=["dev", "prod"],
            help=f"Mode for {subcommand_name.capitalize()}. By default takes env variable HOMELAB_ENV",
        )
        subcommand.add_argument("--dry-run", action="store_true", help="Dry run")
        if subcommand_name == "deploy":
            deploy_when_group = subcommand.add_mutually_exclusive_group()
            deploy_when_group.add_argument(
                "--onchange",
                action="store_true",
                help="Deploy app only when build changed. When there is no change, app is not restarted.",
            )
            deploy_when_group.add_argument(
                "--always",
                action="store_true",
                help="Deploy app always, regardless if the build changed or not.",
            )
            subcommand.add_argument("--with-secrets", action="store_true", help="Also regenerate secrets")
        if subcommand_name in ["deploy", "build"]:
            subcommand.add_argument(
                "--pull",
                action="store_true",
                help="Pull latest docker image from upstream registry",
            )
        if subcommand_name == "secrets":
            online_group = subcommand.add_mutually_exclusive_group()
            online_group.add_argument("--online", action="store_true", help="Access vaultwarden for secrets")
            online_group.add_argument(
                "--offline",
                action="store_true",
                help="Only generate secrets locally, do not access vaultwarden",
            )

    args = parser.parse_args(argv)

    command = args.subcommand
    is_dryrun = args.dry_run

    if command == "deploy":
        when_mode = "onchange" if (hasattr(args, "onchange") and args.onchange is True) else "always" if (hasattr(args, "always") and args.always is True) else "always"
        include_secrets = hasattr(args, "with_secrets") and args.with_secrets is True
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
    symlink_app()
    run_main_command(command)


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except KeyboardInterrupt:
        sys.exit(0)
