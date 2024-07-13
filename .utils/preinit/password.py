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
    parser.add_argument("--only-alphanumeric", action="store_true", default=False)
    args = parser.parse_args(sys.argv[1:])

    file_output = args.output
    only_alphanumeric = args.only_alphanumeric

    lowercase_chars = random.choices(string.ascii_lowercase, k=random.randint(10, 12))
    uppercase_chars = random.choices(string.ascii_uppercase, k=random.randint(10, 12))
    numbers_chars = random.choices(string.digits, k=random.randint(10, 12))
    password_chars = lowercase_chars + uppercase_chars + numbers_chars

    if not only_alphanumeric:
        special_chars = random.choices("$&*%<>?!_+-|", k=random.randint(6, 8))
        password_chars += special_chars

    random.shuffle(password_chars)
    password = "".join(password_chars)

    # Make sure the password starts and ends with alphanumeric character
    extra_chars = random.choices(string.ascii_lowercase + string.ascii_uppercase + string.digits, k=2)
    password = f"{extra_chars[0]}{password}{extra_chars[1]}"

    if file_output == "-":
        print(password)
    else:
        os.makedirs(path.dirname(file_output), exist_ok=True)
        with open(file_output, "w") as file:
            print(password, file=file, sep="", end="")
