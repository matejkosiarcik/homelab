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


def get_site_and_git_dirs() -> tuple[Path, Path]:
    """Validate the current directory before creating logs or running tasks."""
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

    if not re.fullmatch(r"sites/[^/]+", relative_dir.as_posix()):
        raise ValueError(f"Run site tasks from <git-dir>/sites/<site>; got: {current_dir}")
    if not (current_dir / "servers").is_dir():
        raise ValueError(f"Site servers directory is missing: {current_dir / 'servers'}")
    return current_dir, repository_dir


class LogFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        timestamp = datetime.fromtimestamp(record.created, UTC).isoformat(timespec="milliseconds").replace("+00:00", "Z")
        message = record.getMessage().strip()
        if record.exc_info:
            message = f"{message}\n{self.formatException(record.exc_info)}"
        if record.stack_info:
            message = f"{message}\n{self.formatStack(record.stack_info)}"
        return "\n".join(f"{timestamp} [{record.levelname}]: {line}" for line in message.split("\n"))


@dataclass
class MainConfig:
    servers: list[str]
    env_mode: str
    when_mode: str = ""
    is_dryrun: bool = False
    is_pull: bool = False
    include_secrets: bool = False
    only_apps: str | None = None
    skip_apps: str | None = None


def get_servers_list(site_dir: Path, only_servers: str | None, skip_servers: str | None) -> list[str]:
    servers_dir = site_dir / "servers"
    all_servers = [item.name for item in sorted(servers_dir.iterdir()) if item.is_dir() and not item.name.startswith(".") and (item / "docker-apps").is_dir()]

    def matching_servers(patterns: list[str]) -> list[str]:
        return list(dict.fromkeys(server for pattern in patterns for server in all_servers if fnmatch.fnmatchcase(server, f"*{pattern}*")))

    servers = []
    priority_file = servers_dir / "priority.txt"
    if priority_file.exists():
        with priority_file.open(encoding="utf-8") as file:
            patterns = [pattern for line in file if (pattern := line.split("#", maxsplit=1)[0].strip())]
        servers.extend(matching_servers(patterns))
    servers.extend(server for server in all_servers if server not in servers)

    if only_servers:
        servers = matching_servers([pattern for pattern in only_servers.split(",") if pattern])
    if skip_servers:
        skipped = matching_servers([pattern for pattern in skip_servers.split(",") if pattern])
        servers = [server for server in servers if server not in skipped]
    return servers


def main(argv: list[str]) -> None:
    try:
        site_dir, git_dir = get_site_and_git_dirs()
    except ValueError as error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(2)

    parser = argparse.ArgumentParser(prog="task")
    subparsers = parser.add_subparsers(dest="subcommand", required=True)
    for command in ["build", "debug-compose", "deploy", "install", "restart", "secrets", "start", "stop"]:
        subcommand = subparsers.add_parser(command, help=f"{command.replace('-', ' ').capitalize()} on site servers")
        subcommand.add_argument("--mode", choices=["dev", "prod"], help="Mode; defaults to HOMELAB_ENV")
        subcommand.add_argument("--dry-run", action="store_true", help="Dry run")
        subcommand.add_argument("--only", help="Select servers matching these comma-separated patterns")
        subcommand.add_argument("--skip", help="Exclude servers matching these comma-separated patterns")
        subcommand.add_argument("--only-apps", help="Select apps matching these comma-separated patterns on each server")
        subcommand.add_argument("--skip-apps", help="Exclude apps matching these comma-separated patterns on each server")
        if command == "deploy":
            when_group = subcommand.add_mutually_exclusive_group()
            when_group.add_argument("--onchange", dest="when_mode", action="store_const", const="onchange")
            when_group.add_argument("--always", dest="when_mode", action="store_const", const="always")
            subcommand.add_argument("--with-secrets", action="store_true", help="Also regenerate secrets")
        if command in ["build", "deploy"]:
            subcommand.add_argument("--pull", action="store_true", help="Pull latest upstream images")

    args = parser.parse_args(argv)
    env_mode = args.mode or os.environ.get("HOMELAB_ENV")
    if env_mode not in ["dev", "prod"]:
        parser.error("Mode must be dev or prod; pass --mode or set HOMELAB_ENV")

    main_config = MainConfig(
        servers=get_servers_list(site_dir, args.only, args.skip),
        env_mode=env_mode,
        when_mode=(args.when_mode or ("always" if env_mode == "dev" else "onchange")) if args.subcommand == "deploy" else "",
        is_dryrun=args.dry_run,
        is_pull=getattr(args, "pull", False),
        include_secrets=getattr(args, "with_secrets", False),
        only_apps=args.only_apps,
        skip_apps=args.skip_apps,
    )

    start_datetime = datetime.now().astimezone()
    start_time = time.time()
    start_datestr = os.environ.setdefault("START_DATE", start_datetime.strftime(r"%Y-%m-%d_%H-%M-%S"))
    log_file = git_dir / ".logs" / start_datestr / "site.txt"
    log_file.parent.mkdir(parents=True, exist_ok=True)
    log = logging.getLogger("site-helpers")
    log.setLevel(logging.INFO)
    formatter = LogFormatter()
    for handler in [logging.StreamHandler(sys.stderr), logging.FileHandler(log_file)]:
        handler.setFormatter(formatter)
        log.addHandler(handler)

    site_action(args.subcommand, main_config, site_dir, log, start_time)


def site_action(action: str, main_config: MainConfig, site_dir: Path, log: logging.Logger, start_time: float) -> None:
    cli_args = ["--mode", main_config.env_mode]
    if main_config.is_dryrun:
        cli_args.append("--dry-run")
    if main_config.is_pull:
        cli_args.append("--pull")
    if main_config.include_secrets:
        cli_args.append("--with-secrets")
    if main_config.when_mode:
        cli_args.append(f"--{main_config.when_mode}")
    if main_config.only_apps:
        cli_args.extend(["--only", main_config.only_apps])
    if main_config.skip_apps:
        cli_args.extend(["--skip", main_config.skip_apps])

    log.info("↓ %s on site servers", action.replace("-", " ").capitalize())
    for server in main_config.servers:
        log.info("Server: %s", server)
        subprocess.check_call(["task", action, "--", *cli_args], cwd=site_dir / "servers" / server)
        print("\n---\n")

    total_elapsed_mins, total_elapsed_secs = divmod(int(time.time() - start_time), 60)
    log.info("✔ %s on site servers %02d:%02d", action.replace("-", " ").capitalize(), total_elapsed_mins, total_elapsed_secs)


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except KeyboardInterrupt:
        sys.exit(0)
