#!/usr/bin/env python3

import argparse
import datetime
import os
import queue
import sys
import threading
from os import path
from typing import Deque

# pylint: disable=E0401
from gpiozero import Button, DigitalOutputDevice  # type: ignore

# thread communication
commands_queue = queue.SimpleQueue()  # type: Deque[str]

# Connected hardware
button_device = Button(25)
output_device = DigitalOutputDevice(23)

output_status = False
# TODO: File location from within --status-dir
output_status_file = "status.txt"
output_status_last_changed_datetime = datetime.datetime.fromtimestamp(0, datetime.UTC)


def button_press():
    global output_status_last_changed_datetime

    debounce_interval = datetime.timedelta(seconds=0.2)
    current_datetime = datetime.datetime.now(datetime.UTC)
    timeoffset = current_datetime - output_status_last_changed_datetime

    if timeoffset > debounce_interval:
        output_status_last_changed_datetime = current_datetime
        set_output_status(not output_status)


def set_output_status(status: bool):
    global output_status
    output_status = status
    print(f"Turning lamp {'ON' if status else 'OFF'}")
    output_status_int = 1 if output_status else 0
    output_device.value = output_status_int
    with open(output_status_file, "w", encoding="utf-8") as status_file:
        print(f"{output_status_int}", file=status_file)


# Run a thread which listens to FIFO pipe and forwards received commands into task queue
def run_pipe_thread(status_dir: str):
    if not path.exists(status_dir):
        os.mkdir(status_dir)

    pipe_path = path.join(status_dir, "commands.pipe")
    if not path.exists(pipe_path):
        os.mkfifo(pipe_path)

    while True:
        with open(pipe_path, "r", encoding="utf-8") as fifo_file:
            while True:
                data = fifo_file.read()
                if len(data) == 0:
                    break
                commands_queue.put(data)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog="hardware-controller")
    parser.add_argument("--status-dir", type=str, required=False, default=".")
    args = parser.parse_args(sys.argv[1:])

    # Read previous status (graceful restart)
    with open(output_status_file, "a", encoding="utf-8"):
        pass
    with open(output_status_file, "r", encoding="utf-8") as previous_status_file:
        previous_status = previous_status_file.read().strip()
        output_status = previous_status == "1"
    set_output_status(output_status)

    # setup button handling
    button_device.when_activated = button_press

    threading.Thread(target=run_pipe_thread, daemon=True, args=[args.status_dir]).start()

    while True:
        command = commands_queue.get()
        if command == "turn-on":
            set_output_status(True)
        elif command == "turn-off":
            set_output_status(False)
        else:
            print(f"Unrecognized command: {command}", file=sys.stderr)
