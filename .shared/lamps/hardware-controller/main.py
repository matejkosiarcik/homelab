#!/usr/bin/env python3

import argparse
import datetime
import json
import queue
import sys
from http import HTTPStatus
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from os import path

import jsonschema  # type: ignore

# pylint: disable=E0401
from gpiozero import Button, DigitalOutputDevice  # type: ignore

# thread communication
commands_queue: queue.SimpleQueue[str] = queue.SimpleQueue()

# Connected hardware
button_device = Button(25)
output_device = DigitalOutputDevice(23)

output_status: bool = False
output_status_file_path: str = ""
output_status_last_changed_datetime = datetime.datetime.fromtimestamp(0, datetime.UTC)

commands_pipe_path: str = ""


def handle_button_press():
    # pylint: disable=W0603
    global output_status_last_changed_datetime

    debounce_interval = datetime.timedelta(seconds=0.2)
    current_datetime = datetime.datetime.now(datetime.UTC)
    timeoffset = current_datetime - output_status_last_changed_datetime

    if timeoffset > debounce_interval:
        output_status_last_changed_datetime = current_datetime
        set_output_status(not output_status)


def set_output_status(status: bool):
    # pylint: disable=W0603
    global output_status
    output_status = status
    print(f"Turning lamp {'ON' if status else 'OFF'}")
    output_status_int = 1 if output_status else 0
    output_device.value = output_status_int
    with open(output_status_file_path, "w", encoding="utf-8") as status_file:
        print(f"{output_status_int}", file=status_file)


statusSchema = {
    "type": "object",
    "properties": {
        "status": {
            "type": "string",
            "enum": ["on", "off"],
        },
    },
    "required": ["status"],
}


# This server handles only chnages (POST requests)
class RequestHandler(BaseHTTPRequestHandler):
    # pylint: disable=C0103
    def do_POST(self):
        content_len = int(self.headers.get("Content-Length", failobj=0))
        request_str = self.rfile.read(content_len)

        try:
            request_obj = json.loads(request_str)
        except ValueError:
            self.send_response(HTTPStatus.BAD_REQUEST)
            self.end_headers()
            self.wfile.write("Invalid request JSON data - unparsable\n".encode("utf-8"))
            return

        try:
            jsonschema.validate(request_obj, statusSchema)
        except jsonschema.exceptions.ValidationError:
            self.send_response(HTTPStatus.BAD_REQUEST)
            self.end_headers()
            self.wfile.write("Invalid request JSON schema - validation failed\n".encode("utf-8"))
            return

        new_status_bool: bool = request_obj["status"] == "on"
        set_output_status(new_status_bool)

        self.send_response(HTTPStatus.OK)
        self.end_headers()
        output = json.dumps({"status": "on" if output_status else "off"}) + "\n"
        self.wfile.write(output.encode("utf-8"))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog="hardware-controller")
    parser.add_argument("--status-dir", type=str, required=False, default=".")
    args = parser.parse_args(sys.argv[1:])

    output_status_file_path = path.join(args.status_dir, "status.txt")
    commands_pipe_path = path.join(args.status_dir, "commands.pipe")

    # Read previous status (graceful restart)
    with open(output_status_file_path, "a", encoding="utf-8"):
        pass
    with open(output_status_file_path, "r", encoding="utf-8") as previous_status_file:
        previous_status = previous_status_file.read().strip()
        output_status = previous_status == "1"
    set_output_status(output_status)

    # setup button handling
    button_device.when_activated = handle_button_press

    httpd = ThreadingHTTPServer(("", 8081), RequestHandler)
    httpd.serve_forever()
