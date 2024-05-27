from gpiozero import Button, DigitalOutputDevice
from signal import pause
# from time import sleep
import datetime


button_device = Button(25)
output_device = DigitalOutputDevice(23)

output_status = False
output_status_file = 'status.txt'
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
    output_status_int = 1 if output_status else 0
    output_device.value = output_status_int
    with open(output_status_file, 'w') as status_file:
        print(f'{output_status_int}', file=status_file)


if __name__ == '__main__':
    # Read previous status (graceful restart)
    with open(output_status_file, 'a'):
        pass
    with open(output_status_file, 'r') as previous_status_file:
        previous_status = previous_status_file.read().strip()
        output_status = True if previous_status == '1' else False
    set_output_status(output_status)

    button_device.when_activated = button_press

    try:
        pause()
    except:
        output_device.off()
