#!/usr/bin/env python3

import argparse
import collections
import grp
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
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path


def get_app_and_git_dirs() -> tuple[Path, Path]:
    """Return the app directory only when Task was invoked from a deployed app."""
    current_dir = Path.cwd().resolve()
    try:
        repository_dir = Path(
            subprocess.check_output(
                ["git", "rev-parse", "--show-toplevel"],
                cwd=current_dir,
                stderr=subprocess.DEVNULL,
                encoding="utf-8",
            ).strip()
        ).resolve()
    except subprocess.CalledProcessError as error:
        raise ValueError(f"Current directory is not in a Git working tree: {current_dir}") from error

    try:
        relative_dir = current_dir.relative_to(repository_dir)
    except ValueError as error:
        raise ValueError(f"Current directory is outside this Git working tree: {current_dir}") from error

    expected_path = "<git-dir>/servers/<server>/docker-apps/<app>"
    if not re.fullmatch(r"servers/[^/]+/docker-apps/[^/]+", relative_dir.as_posix()):
        raise ValueError(f"Run app tasks from {expected_path}; got: {current_dir}")

    if not (current_dir / "config" / "config.yml").is_file():
        raise ValueError(f"App config is missing from {current_dir}; expected: {current_dir / 'config' / 'config.yml'}")

    return current_dir, repository_dir


try:
    app_dir, git_dir = get_app_and_git_dirs()
except ValueError as error:
    print(f"Error: {error}", file=sys.stderr)
    sys.exit(2)


local_tz = datetime.now().astimezone().tzinfo
start_datestr = os.environ["START_DATE"] if os.environ.get("START_DATE") is not None else datetime.now(local_tz).strftime(r"%Y-%m-%d_%H-%M-%S")

main_log_dir = app_dir / "app-logs"
log_dir = main_log_dir / ".meta"
log_file_main = log_dir / "task.log"

is_ci = bool(os.environ.get("GITHUB_ACTIONS") == "true" or os.environ.get("CIRCLECI") == "true" or os.environ.get("CI") in ["1", "true"])
cpu_count = os.cpu_count() or 1

if log_dir.exists():
    shutil.rmtree(log_dir)
log_dir.mkdir(parents=True, exist_ok=True)


@dataclass
class AppConfig:
    app_fullname: str = ""
    app_shortname: str = ""
    app_type: str = ""
    app_ip: str = ""
    app_domain: str = ""


@dataclass
class MainConfig:  # pylint: disable=too-many-instance-attributes
    env_mode: str
    when_mode: str = ""
    is_dryrun: bool = False
    is_pull: bool = False
    include_secrets: bool = False
    app: AppConfig = field(default_factory=AppConfig)
    docker_compose_args: list[str] = field(default_factory=list)
    docker_buildx_bake_args: list[str] = field(default_factory=list)
    docker_compose_command_args: list[str] = field(default_factory=list)


main_config: MainConfig = MainConfig()


class LogFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        timestamp = datetime.fromtimestamp(record.created, UTC).isoformat(timespec="milliseconds").replace("+00:00", "Z")
        message = record.getMessage().strip()
        if record.exc_info:
            message = f"{message}\n{self.formatException(record.exc_info)}"
        if record.stack_info:
            message = f"{message}\n{self.formatStack(record.stack_info)}"
        return "\n".join(f"{timestamp} [{record.levelname}]: {line}" for line in message.split("\n"))


log = logging.getLogger()
log.setLevel(logging.INFO)
log_formatter = LogFormatter()
log_handler = logging.StreamHandler(sys.stderr)
log_handler.setFormatter(log_formatter)
log.addHandler(log_handler)
log_file_handler = logging.FileHandler(log_file_main)
log_file_handler.setFormatter(log_formatter)
log.addHandler(log_file_handler)


# Write current anticache.txt
with open(
    git_dir / "docker-images" / ".shared" / "anticache.txt",
    "w",
    encoding="utf-8",
) as anticachefile:
    print(
        f"This file is for cache busting\nDatetime: {datetime.now(local_tz).isoformat()}",
        file=anticachefile,
    )


@dataclass
class AsciiChars:
    checkmark: str = "✔"
    cross: str = "✘"
    skip: str = "⏭"

    def __post_init__(self):
        def tty_supports_color():
            return sys.stdout.isatty() and os.environ.get("TERM") not in (None, "", "dumb")

        if tty_supports_color():
            self.checkmark = f"\033[32m{self.checkmark}\033[0m"
            self.cross = f"\033[31m{self.cross}\033[0m"
            self.skip = f"\033[36m{self.skip}\033[0m"


ascii_chars = AsciiChars()


def write_log_file_header(command_log_file: Path):
    with open(command_log_file, "w", encoding="utf-8") as file:
        file.write(f"Start date: {start_datestr}\n\n")


def write_log_file_footer(command_log_file: Path):
    with open(command_log_file, "a", encoding="utf-8") as file:
        file.write(f"\nEnd date: {start_datestr}\n")


def get_canonical_app_value(function_name: str) -> str:
    """Read an app value from the shared canonical app-entry resolver."""
    if function_name not in ["get_app_domain", "get_app_full_name_machine", "get_app_ip", "get_app_type"]:
        raise ValueError(f"Unsupported canonical app function: {function_name}")

    resolver_path = git_dir / "docker-images" / ".shared" / "build-utils" / "parse-app-entry-utils.sh"
    return subprocess.check_output(
        ["sh", "-c", f'. "$1"; {function_name} "$2"', "sh", resolver_path, app_dir],
        text=True,
    ).strip()


def load_app_config():
    config_path = app_dir / "config" / "config.yml"
    if not config_path.exists():
        raise FileNotFoundError("App config.yml not found")

    # Set name properties
    app_config = main_config.app
    app_config.app_shortname = app_dir.name.lstrip(".")
    app_config.app_type = get_canonical_app_value("get_app_type")
    app_config.app_fullname = get_canonical_app_value("get_app_full_name_machine")

    # Set network properties
    if main_config.env_mode == "prod":
        app_config.app_domain = get_canonical_app_value("get_app_domain")
        app_config.app_ip = get_canonical_app_value("get_app_ip")
    else:
        app_config.app_domain = "localhost"
        app_config.app_ip = "127.0.0.1"


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
    app_config = main_config.app
    env_mode = main_config.env_mode
    default_protocol = "smb" if "samba" in app_config.app_fullname else "https"
    default_port = "8443" if env_mode == "dev" else ""
    port_delimiter = ":" if default_port != "" else ""
    default_env_values = {
        "COMPOSE_PROJECT_NAME": app_config.app_shortname,
        "DOCKER_COMPOSE_APP_FULLNAME": app_config.app_fullname,
        "DOCKER_COMPOSE_APP_SHORTNAME": app_config.app_shortname,
        "DOCKER_COMPOSE_APP_PATH": str(app_dir),
        "DOCKER_COMPOSE_APP_TYPE": app_config.app_type,
        "DOCKER_COMPOSE_ENV": env_mode,
        "DOCKER_COMPOSE_NETWORK_DOMAIN": app_config.app_domain,
        "DOCKER_COMPOSE_NETWORK_IP": app_config.app_ip,
        "DOCKER_COMPOSE_NETWORK_URL": f"{default_protocol}://{app_config.app_domain}{port_delimiter}{default_port}",
        "DOCKER_COMPOSE_REPOROOT_PATH": str(git_dir),
        "DOCKER_COMPOSE_UID": str(os.getuid()) if env_mode == "prod" else "1000",
        "DOCKER_COMPOSE_GID": str(os.getgid()) if env_mode == "prod" else "1000",
        "DOCKER_COMPOSE_DOCKER_GID": str(grp.getgrnam("docker").gr_gid) if env_mode == "prod" else "0",
    }

    # Remove old environment values
    for key in default_env_values:
        if os.environ.get(key) is not None:
            os.environ.pop(key)

    # Load env files
    if (env_file := Path("config") / "compose.env").exists():
        load_env_file(env_file)
    if (env_file := Path("config") / f"compose-{env_mode}.env").exists():
        load_env_file(env_file)

    # Fill in default values
    for key, default_value in default_env_values.items():
        os.environ.setdefault(key, default_value)

    for i in range(2, 10):
        if os.environ.get(f"DOCKER_COMPOSE_NETWORK_DOMAIN_{i}") is not None and os.environ.get(f"DOCKER_COMPOSE_NETWORK_URL_{i}") is None:
            domain = os.environ[f"DOCKER_COMPOSE_NETWORK_DOMAIN_{i}"]
            os.environ[f"DOCKER_COMPOSE_NETWORK_URL_{i}"] = f"{default_protocol}://{domain}"
        elif os.environ.get(f"DOCKER_COMPOSE_NETWORK_URL_{i}") is None:
            domain = os.environ["DOCKER_COMPOSE_NETWORK_DOMAIN"]
            os.environ[f"DOCKER_COMPOSE_NETWORK_URL_{i}"] = f"{default_protocol}://{domain}"
            os.environ[f"DOCKER_COMPOSE_NETWORK_DOMAIN_{i}"] = domain


def symlink_app():
    app_compose_dir = git_dir / "docker-compose" / main_config.app.app_type
    for file in ["compose.yml", "compose.override.yml", "compose.prod.yml"]:
        try:
            os.remove(file)
        except OSError:
            pass
    os.symlink(app_compose_dir / "compose.yml", "compose.yml")
    os.symlink(app_compose_dir / "compose.override-dev.yml", "compose.override.yml")
    os.symlink(app_compose_dir / "compose.override-prod.yml", "compose.prod.yml")


def get_docker_compose_config() -> str:
    return subprocess.check_output(["docker", "compose", *main_config.docker_compose_args, "config", "--format", "json"], encoding="utf-8")


def get_docker_images_shasum(config: str) -> str:
    config_obj = json.loads(config)
    image_names = sorted(service["image"] for service in config_obj["services"].values())
    output = []
    for image in image_names:
        try:
            inspect_output = subprocess.check_output(
                ["docker", "image", "inspect", image, "--format", "json"],
                stderr=subprocess.DEVNULL,
                encoding="utf-8",
            )
            layers_output = (
                subprocess.check_output(
                    ["jq", "-r", '(.[0].RootFS.Layers // ["N/A"])[]'],
                    input=inspect_output,
                    encoding="utf-8",
                )
                .replace("\n", " ")
                .strip()
            )
        except subprocess.CalledProcessError:
            layers_output = "N/A"
        sha = hashlib.sha1(layers_output.encode()).hexdigest()
        output.append(f"{image} {sha}")
    return "\n".join(output)


def get_docker_containers_are_running(config_json: str) -> bool:
    if main_config.when_mode == "always":
        return False

    config_obj = json.loads(config_json)
    expected_containers = {service["container_name"] for service in config_obj["services"].values()}
    running_containers = set(
        subprocess.check_output(
            ["docker", "compose", *main_config.docker_compose_args, "ps", "--status", "running", "--format", "{{.Name}}"],
            text=True,
        ).splitlines()
    )
    missing_containers = sorted(expected_containers - running_containers)

    return not missing_containers


# pylint: disable=too-many-locals
def run_with_spinner(
    command: list[str],
    description_progress: str,
    description_done: str,
    command_log_file: Path,
    print_output: bool,
):
    start_time = time.time()
    done = threading.Event()
    global_exit = False
    last_output_line = ""
    last_exit_code: int | None = None

    write_log_file_header(command_log_file)

    def subprocess_main():
        nonlocal last_exit_code
        master_fd, slave_fd = pty.openpty()  # This is for making the subprocess think the output is a TTY and it enables colored output
        with open(command_log_file, "a", encoding="utf-8") as file, subprocess.Popen(command, stdout=slave_fd, stderr=slave_fd, stdin=slave_fd, text=True, bufsize=1, close_fds=True) as last_process:
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
        spin_timeout = 10 if is_ci else 0.1

        spinner_chars = "▖▘▝▗"
        spinner_index = 0

        if print_output:
            print(f"↓ {description_progress} {os.environ.get('DOCKER_COMPOSE_APP_SHORTNAME')} 00:00")

        while not done.is_set():
            elapsed = time.time() - start_time
            elapsed_mins, elapsed_secs = divmod(int(elapsed), 60)
            last_output_line = f"{spinner_chars[math.floor(spinner_index)]} {description_progress} {os.environ.get('DOCKER_COMPOSE_APP_SHORTNAME')} {elapsed_mins:02d}:{elapsed_secs:02d} "
            if global_exit:
                break
            if not print_output:
                print(f"\r{last_output_line}", end="", flush=True)
            spinner_index += 1
            spinner_index %= len(spinner_chars)
            done.wait(spin_timeout)

        subprocess_thread.join()
    except KeyboardInterrupt:
        global_exit = True
        done.set()
    finally:
        done.set()
        total_elapsed = time.time() - start_time
        total_elapsed_mins, total_elapsed_secs = divmod(int(total_elapsed), 60)
        status_marker = ascii_chars.checkmark if last_exit_code == 0 and not global_exit else ascii_chars.cross
        print(f"\r{' ' * len(last_output_line)}", end="", flush=True)
        print(
            f"\r{status_marker} {description_done} {os.environ.get('DOCKER_COMPOSE_APP_SHORTNAME')} {total_elapsed_mins:02d}:{total_elapsed_secs:02d} ",
            file=sys.stderr,
        )
        write_log_file_footer(command_log_file)

        if last_exit_code != 0 and not global_exit:
            log.error("Process exit code: %s", last_exit_code)
            log.error("Process args: %s", " ".join(command))
            log.error("Process output:")
            with open(command_log_file, "r", encoding="utf-8") as file:
                for line in collections.deque(file, maxlen=50):
                    log.error(">> %s", line.rstrip())
            log.error('See logfile "%s" for all details.', command_log_file.name)
            sys.exit(1)

    if global_exit:
        sys.exit(0)


def docker_build():
    commands = ["docker", "buildx", "bake", *main_config.docker_buildx_bake_args]
    docker_log_file = log_dir / "docker-build.log"
    run_with_spinner(commands, "Building", "Build", docker_log_file, False)


def docker_debug_compose():
    compose_file = log_dir / f"compose-{main_config.env_mode}.yml"
    commands = ["docker", "compose", *main_config.docker_compose_args, "config", "--output", str(compose_file)]
    docker_log_file = log_dir / "docker-debug-compose.log"
    run_with_spinner(commands, "Resolving compose config for", "Resolve compose config for", docker_log_file, False)
    log.info("Resolved compose config written to %s", compose_file)


def docker_stop():
    commands = ["docker", "compose", *main_config.docker_compose_args, "down", *main_config.docker_compose_command_args]
    docker_log_file = log_dir / "docker-stop.log"
    run_with_spinner(commands, "Stopping", "Stop", docker_log_file, False)


def clear_app_runtime_logs():
    for log_entry in os.scandir(main_log_dir):
        if log_entry.name == log_dir.name:
            continue
        if log_entry.is_dir(follow_symlinks=False):
            shutil.rmtree(log_entry.path)
        else:
            os.unlink(log_entry.path)


def docker_start():
    clear_app_runtime_logs()

    config_json = get_docker_compose_config()
    config_obj = json.loads(config_json)

    # Extract all volumes from docker-compose yaml
    volumes: list[str] = []
    for service in config_obj["services"]:
        if "volumes" not in config_obj["services"][service]:
            continue
        for volume in config_obj["services"][service]["volumes"]:
            volumes.append(volume["source"])

    # Precreate all volumes - this ensures proper directory permissions
    for volume in volumes:
        created = False
        if not Path(volume).exists():
            Path(volume).mkdir(parents=True, exist_ok=True)
            created = True
            os.chmod(volume, mode=0o755)  # TODO: Remove this line and uncomment code below
        if created or volume.startswith(str(app_dir)):
            pass  # TODO: Re-enable code below
            # os.chown(volume, uid=current_user, gid=current_user_group)
            # os.chmod(volume, mode=0o755)  # TODO: Change to 0o750

    commands = [
        "docker",
        "compose",
        *main_config.docker_compose_args,
        "up",
        "--force-recreate",
        "--always-recreate-deps",
        "--remove-orphans",
        "--no-build",
        *main_config.docker_compose_command_args,
        *(["--detach", "--wait"] if main_config.env_mode == "prod" else []),
    ]
    docker_log_file = log_dir / "docker-start.log"
    run_with_spinner(commands, "Starting", "Start", docker_log_file, main_config.env_mode == "dev")


def create_secrets():
    docker_log_file = log_dir / "secrets.log"
    commands = [
        "sh",
        f"{git_dir}/utils/secrets-helpers/main.sh",
        f"--{main_config.env_mode}",
    ]
    run_with_spinner(commands, "Secrets", "Secrets", docker_log_file, False)


def run_main_command(command: str):
    main_config.docker_compose_args = [
        "--file",
        "compose.yml",
        "--file",
        f"compose.{'prod' if main_config.env_mode == 'prod' else 'override'}.yml",
        "--project-name",
        os.environ["DOCKER_COMPOSE_APP_SHORTNAME"],
        "--progress",
        "plain",
        "--parallel",
        str(int(max(cpu_count // 2, 1))),
    ]
    main_config.docker_compose_command_args = ["--dry-run"] if main_config.is_dryrun else []
    main_config.docker_buildx_bake_args = [
        f"--allow=fs.read={git_dir}",
        "--file",
        "compose.yml",
        "--file",
        f"compose.{'prod' if main_config.env_mode == 'prod' else 'override'}.yml",
        "--progress",
        "plain",
        "--jobs",
        str(max(cpu_count // 2, 1)),
        "--load",
        "--provenance=false",
        *(["--print"] if main_config.is_dryrun else []),
        *(["--pull"] if main_config.is_pull else []),
    ]

    # Check if docker-compose stack exists
    compose_path = git_dir / "docker-compose" / os.environ["DOCKER_COMPOSE_APP_TYPE"]
    if not compose_path.is_dir():
        log.error("Docker compose stack for app %s not found", os.environ.get("DOCKER_COMPOSE_APP_TYPE"))
        sys.exit(1)

    # Execute commands
    if command == "build":
        docker_build()
    elif command == "debug-compose":
        docker_debug_compose()
    elif command == "deploy":
        if main_config.include_secrets:
            create_secrets()
        config_json = get_docker_compose_config()
        shasum_before = get_docker_images_shasum(config_json)
        docker_build()
        shasum_after = get_docker_images_shasum(config_json)
        images_changed = shasum_before != shasum_after
        all_containers_running = get_docker_containers_are_running(config_json)
        if main_config.when_mode == "always" or images_changed or not all_containers_running:
            docker_stop()
            docker_start()
        else:
            print(f"{ascii_chars.skip} Stop skipped")
            print(f"{ascii_chars.skip} Start skipped")
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
        log.error("Unrecognized command '%s'", command)
        sys.exit(1)


def main(argv):
    global main_config  # pylint: disable=global-statement
    parser = argparse.ArgumentParser(prog="task")
    subparsers = parser.add_subparsers(dest="subcommand")
    subcommands = [
        subparsers.add_parser("build", help="Build this app"),
        subparsers.add_parser("debug-compose", help="Dump resolved compose config for this app"),
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
                dest="when_mode",
                action="store_const",
                const="onchange",
                help="Restart app only when build changed (default in prod)",
            )
            deploy_when_group.add_argument(
                "--always",
                dest="when_mode",
                action="store_const",
                const="always",
                help="Restart app always, regardless if the build changed or not (default in dev)",
            )
            subcommand.add_argument("--with-secrets", action="store_true", help="Also regenerate secrets")
        if subcommand_name in ["deploy", "build"]:
            subcommand.add_argument(
                "--pull",
                action="store_true",
                help="Pull latest docker image from upstream registry",
            )

    args = parser.parse_args(argv)

    command = args.subcommand
    env_mode = args.mode
    if env_mode is None:
        env_mode = os.environ.get("HOMELAB_ENV")
    if env_mode is None:
        log.error("Mode is unset, either pass in: `--mode dev|prod` or set env variable: `HOMELAB_ENV=dev|prod`")
        sys.exit(1)
    if env_mode not in ["dev", "prod"]:
        log.error("Invalid mode, got: %s, valid values are: dev|prod", env_mode)
        sys.exit(1)

    main_config = MainConfig(
        env_mode=env_mode,
        when_mode=(args.when_mode or ("always" if env_mode == "dev" else "onchange")) if command == "deploy" else "",
        is_dryrun=args.dry_run,
        is_pull=getattr(args, "pull", False) is True,
        include_secrets=getattr(args, "with_secrets", False) is True if command == "deploy" else False,
    )

    if command not in ["build", "debug-compose", "deploy", "restart", "secrets", "start", "stop"]:
        log.error("Unrecognized command: %s", command)
        sys.exit(1)

    load_app_config()
    load_full_env()
    symlink_app()
    run_main_command(command)


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except KeyboardInterrupt:
        sys.exit(0)
