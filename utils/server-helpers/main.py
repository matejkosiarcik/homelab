#!/usr/bin/env python3

import argparse
import fnmatch
import logging
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path


def get_server_and_git_dirs() -> tuple[Path, Path]:
    """Return the server directory only when invoked from a server directory."""
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

    if not re.fullmatch(r"sites/[^/]+/servers/[^/]+", relative_dir.as_posix()):
        raise ValueError(f"Run server tasks from <git-dir>/sites/<site>/servers/<server>; got: {current_dir}")
    if not (current_dir / "docker-apps").is_dir():
        raise ValueError(f"Server docker-apps directory is missing: {current_dir / 'docker-apps'}")

    return current_dir, repository_dir


try:
    server_dir, git_dir = get_server_and_git_dirs()
except ValueError as error:
    print(f"Error: {error}", file=sys.stderr)
    sys.exit(2)


local_tz = datetime.now().astimezone().tzinfo
start_datetime = datetime.now(local_tz)
start_datestr = start_datetime.strftime(r"%Y-%m-%d_%H-%M-%S")
start_time = start_datetime.timestamp()
os.environ["START_DATE"] = start_datestr

server_name = server_dir.name
log_file = git_dir / ".logs" / start_datestr / "server.txt"

log_file.parent.mkdir(parents=True, exist_ok=True)


@dataclass
class MainConfig:
    apps: list[str]
    env_mode: str
    when_mode: str = ""
    is_dryrun: bool = False
    is_pull: bool = False
    include_secrets: bool = False


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
log_file_handler = logging.FileHandler(log_file)
log_file_handler.setFormatter(log_formatter)
log.addHandler(log_file_handler)


@dataclass
class AsciiChars:
    checkmark: str = "✔"
    cross: str = "✘"

    def __post_init__(self):
        def tty_supports_color():
            return sys.stdout.isatty() and os.environ.get("TERM") not in (None, "", "dumb")

        if tty_supports_color():
            self.checkmark = f"\033[32m{self.checkmark}\033[0m"
            self.cross = f"\033[31m{self.cross}\033[0m"


ascii_chars = AsciiChars()


def get_apps_list(only_apps: str | None, skip_apps: str | None) -> list[str]:
    all_apps_list: list[str] = []
    apps_list_output: list[str] = []

    # Get a list of all apps
    for item in sorted((server_dir / "docker-apps").iterdir()):
        if item.is_dir() and not item.name.startswith(".") and (item / "config" / "config.yml").is_file():
            all_apps_list.append(item.name)

    def get_matching_apps(app_patterns: list[str]) -> list[str]:
        return list(dict.fromkeys([app_name for app_pattern in app_patterns for app_name in all_apps_list if fnmatch.fnmatchcase(app_name, f"*{app_pattern}*")]))

    # Add priority apps
    priority_file = server_dir / "docker-apps" / "priority.txt"
    if priority_file.exists():
        with priority_file.open(encoding="utf-8") as file:
            priority_apps_list = [app for app in [line.split("#", maxsplit=1)[0].strip() for line in file] if len(app) > 0]
            apps_list_output += get_matching_apps(priority_apps_list)

    # Add rest of the apps
    for item in all_apps_list:
        if item not in apps_list_output:
            apps_list_output.append(item)

    # If "--only" -> only output apps that match it
    if only_apps:
        args_only = [x for x in only_apps.split(",") if len(x) > 0]
        apps_list_output = get_matching_apps(args_only)

    # If "--skip" -> remove apps which match it
    if skip_apps:
        args_skip = [x for x in skip_apps.split(",") if len(x) > 0]
        apps_list_skip = get_matching_apps(args_skip)
        apps_list_output = [app_name for app_name in apps_list_output if app_name not in apps_list_skip]

    return apps_list_output


def main(argv: list[str]):
    parser = argparse.ArgumentParser(prog="task")
    subparsers = parser.add_subparsers(dest="subcommand")
    subcommands = [
        subparsers.add_parser("build", help="Build docker images for all docker apps"),
        subparsers.add_parser("debug-compose", help="Dump resolved compose configs for all docker apps"),
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
        if subcommand_name == "deploy":
            deploy_when_group = subcommand.add_mutually_exclusive_group()
            deploy_when_group.add_argument(
                "--onchange",
                dest="when_mode",
                action="store_const",
                const="onchange",
                help="Restart apps only when build changed (default in prod)",
            )
            deploy_when_group.add_argument(
                "--always",
                dest="when_mode",
                action="store_const",
                const="always",
                help="Restart apps always, regardless if the build changed or not (default in dev)",
            )
            subcommand.add_argument("--with-secrets", action="store_true", help="Also regenerate secrets")
        if subcommand_name in ["deploy", "build"]:
            subcommand.add_argument("--pull", action="store_true", help="Pull latest docker image from upstream registry")

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
        apps=get_apps_list(args.only, args.skip),
        env_mode=env_mode,
        when_mode=(args.when_mode or ("always" if env_mode == "dev" else "onchange")) if command == "deploy" else "",
        is_dryrun=args.dry_run,
        is_pull=getattr(args, "pull", False) is True,
        include_secrets=getattr(args, "with_secrets", False) is True if command == "deploy" else False,
    )

    if command == "install":
        server_install()
        return

    if command in ["build", "debug-compose", "deploy", "restart", "secrets", "start", "stop"]:
        server_action(command, main_config)
        return

    log.error("Unrecognized command: %s", command)
    sys.exit(1)


def server_action(action: str, config: MainConfig):
    action_log = action.replace("-", " ").capitalize()
    if action == "secrets":
        action_log += " for"
    log.info("%s %s docker apps", "↓", action_log)
    print("\n---\n")

    cli_args = ["--mode", config.env_mode]
    if config.is_dryrun:
        cli_args.append("--dry-run")
    if config.is_pull:
        cli_args.append("--pull")
    if action == "deploy" and config.include_secrets:
        cli_args.append("--with-secrets")
    if action == "deploy":
        cli_args.append(f"--{config.when_mode}")

    for app in config.apps:
        subprocess.check_call(["task", action, "--", *cli_args], cwd=server_dir / "docker-apps" / app)
        print("\n---\n")

    total_elapsed = time.time() - start_time
    total_elapsed_mins, total_elapsed_secs = divmod(int(total_elapsed), 60)
    log.info("%s %s docker apps %02d:%02d", ascii_chars.checkmark, action_log, total_elapsed_mins, total_elapsed_secs)


def server_install():
    log.info("%s Installing global server config", "↓")
    subprocess.check_call(["sh", git_dir / "utils" / "server-helpers" / "install.sh"])
    total_elapsed = time.time() - start_time
    total_elapsed_mins, total_elapsed_secs = divmod(int(total_elapsed), 60)
    log.info("%s Install global config %02d:%02d", ascii_chars.checkmark, total_elapsed_mins, total_elapsed_secs)


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except KeyboardInterrupt:
        sys.exit(0)
