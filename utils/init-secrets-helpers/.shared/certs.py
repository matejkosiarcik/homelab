#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
from os import path

if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog="certs")
    parser.add_argument("--output", "-o", type=str, required=False, default="certs")
    # parser.add_argument("--domain", type=str, required=True)
    args = parser.parse_args(sys.argv[1:])

    dir_output = args.output
    os.makedirs(dir_output, exist_ok=True)

    domain = "*.home"  # TODO: Pass domain in argument
    # TODO: Can you put multiple domains here? What is the syntax?
    # Something like "pihole-main.home,*.pihole-main.home"
    openssl_subj = f"/C=SK/ST=Slovakia/L=Bratislava/O=Unknown/OU=Org/CN={domain}"

    subprocess.check_call(["openssl", "genrsa", "-out", path.join(dir_output, "server.key"), "4096"])
    subprocess.check_call(["openssl", "rsa", "-in", path.join(dir_output, "server.key"), "-out", path.join(dir_output, "server.key")])
    subprocess.check_call(["openssl", "req", "-sha256", "-new", "-key", path.join(dir_output, "server.key"), "-out", path.join(dir_output, "server.csr"), "-subj", openssl_subj])
    subprocess.check_call(["openssl", "x509", "-req", "-sha256", "-days", "365", "-in", path.join(dir_output, "server.csr"), "-signkey", path.join(dir_output, "server.key"), "-out", path.join(dir_output, "server.crt")])
