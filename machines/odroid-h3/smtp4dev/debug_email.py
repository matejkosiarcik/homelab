# #!/usr/bin/env python3

import argparse
import sys
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from smtplib import SMTP
from typing import List


def main(argv: List[str]) -> int:
    # Parse arguments
    parser = argparse.ArgumentParser(prog="debug-email.py")
    parser.add_argument("--host", type=str, default="localhost:8025", help="Host IP:Port or Domain:Port")
    args = parser.parse_args(argv)

    host = args.host

    address_from = "sender@test.test"
    address_to = "receiver@test.test"
    subject = "Test subject"

    # Disabled because smtp4dev doesn't show Plain text emails well
    # message_raw = f"from: {address_from}\nto: {address_to}\nsubject: {subject}\n\nTest body line 1\nTest body line 2"
    # with SMTP(host) as smtp:
    #     smtp.sendmail(
    #         from_addr=address_from,
    #         to_addrs=address_to,
    #         msg=message_raw
    #     )

    # message = Message()
    message = MIMEMultipart("alternative")
    message["From"] = address_from
    message["To"] = address_to
    message["Subject"] = subject
    message.attach(MIMEText("Test body line 1<br>Test body line 2", "html"))

    with SMTP(host) as smtp:
        smtp.send_message(message)

    return 0


if __name__ == "__main__":
    exit_code = main(sys.argv[1:])
    sys.exit(exit_code)
