#!/usr/bin/env python3

import argparse
import os
import random
import string
import sys
from os import path

if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog="password")
    parser.add_argument("--output", "-o", type=str, required=False, default="-")
    parser.add_argument("--length", type=int, default=10)
    args = parser.parse_args(sys.argv[1:])

    file_output = args.output
    length = args.length

    secret = "".join(random.choices("".join([string.ascii_lowercase, string.ascii_uppercase, string.digits]), k=length))

    if file_output == "-":
        print(secret)
    else:
        os.makedirs(path.dirname(file_output), exist_ok=True)
        with open(file_output, "w", encoding="utf8") as file:
            print(secret, file=file, sep="", end="")
