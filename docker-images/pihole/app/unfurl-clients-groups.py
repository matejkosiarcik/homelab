#!/usr/bin/env python3
"""Expand Pi-hole client ranges and apply local DNS names to them"""

from __future__ import annotations

import argparse
import csv
import ipaddress
from collections.abc import Iterable
from pathlib import Path

CSV_FIELDS = ("ip", "client", "group")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("clients_groups", type=Path, help="input clients-groups.csv file")
    parser.add_argument("domains_all", type=Path, help="input domains-all.txt file")
    parser.add_argument("domains_apps", type=Path, help="input app domains file")
    parser.add_argument("output", type=Path, help="output clients-groups.txt file")
    return parser.parse_args()


def expanded_ips(value: str, line_number: int) -> Iterable[ipaddress.IPv4Address]:
    """Return the single IPv4 address or inclusive IPv4 range in *value*"""
    start_text, separator, end_text = value.partition("-")
    try:
        start = ipaddress.IPv4Address(start_text.strip())
        end = ipaddress.IPv4Address(end_text.strip()) if separator else start
    except ipaddress.AddressValueError as error:
        raise ValueError(f"Clients CSV line {line_number}: invalid IPv4 address or range {value!r}") from error

    if separator and (not end_text.strip() or start > end):
        raise ValueError(f"Clients CSV line {line_number}: invalid IPv4 range {value!r}")

    return (ipaddress.IPv4Address(address) for address in range(int(start), int(end) + 1))


def load_domain_names(path: Path) -> dict[str, str]:
    """Map IPv4 addresses in a hosts-style domain list to their final name"""
    domain_names: dict[str, str] = {}
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.split("#", maxsplit=1)[0].strip()
        if not line:
            continue

        fields = line.split()
        if len(fields) < 2:
            raise ValueError(f"Domains file line {line_number}: expected an IP address and domain name")

        try:
            ip = ipaddress.IPv4Address(fields[0])
        except ipaddress.AddressValueError:
            # CNAME records begin with the alias rather than an IP address.
            continue

        domain_names[str(ip)] = fields[1].rstrip(".").removesuffix(".matejhome.com")

    return domain_names


def load_clients(
    path: Path, domain_names: dict[str, str], app_ips: set[str]
) -> dict[str, tuple[str, str]]:
    """Expand client rows and retain only the last row for each IP address."""
    clients: dict[str, tuple[str, str]] = {}
    with path.open(encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        if reader.fieldnames != list(CSV_FIELDS):
            raise ValueError(f"Clients CSV header must be {','.join(CSV_FIELDS)!r}")

        for line_number, row in enumerate(reader, start=2):
            if None in row:
                raise ValueError(f"Clients CSV line {line_number}: too many fields")
            if not any((value or "").strip() for value in row.values()):
                continue

            values = {field: (row[field] or "").strip() for field in CSV_FIELDS}
            if not all(values.values()):
                raise ValueError(f"Clients CSV line {line_number}: IP, client, and group are required")

            for ip in expanded_ips(values["ip"], line_number):
                ip_text = str(ip)
                placeholder_ip = ip_text.replace(".", "-")
                client = values["client"].replace("<IP>", placeholder_ip)
                group = values["group"].replace("<IP>", placeholder_ip)
                client = domain_names.get(ip_text, client)
                if ip_text in app_ips:
                    client = f"app--{client}"

                if any(character.isspace() for character in client) or any(
                    character.isspace() for character in group
                ):
                    raise ValueError(
                        f"Clients CSV line {line_number}: expanded client and group values cannot contain whitespace"
                    )

                # Popping first makes output order reflect the final definition, too.
                clients.pop(ip_text, None)
                clients[ip_text] = (client, group)

    return clients


def write_clients(path: Path, clients: dict[str, tuple[str, str]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as output:
        output.write("ip client group\n")
        for ip, (client, group) in clients.items():
            output.write(f"{ip} {client} {group}\n")


def main() -> None:
    args = parse_args()
    domain_names = load_domain_names(args.domains_all)
    app_ips = set(load_domain_names(args.domains_apps))
    clients = load_clients(args.clients_groups, domain_names, app_ips)
    write_clients(args.output, clients)


if __name__ == "__main__":
    main()
