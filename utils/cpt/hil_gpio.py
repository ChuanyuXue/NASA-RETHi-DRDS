## MAX6675

import RPi.GPIO as GPIO
import time


# set pin number for communicate with MAX6675
def set_pin(CS, SCK, SO, UNIT):
    global sck
    sck = SCK
    global so
    so = SO
    global unit
    unit = UNIT

    GPIO.setup(CS, GPIO.OUT, initial=GPIO.HIGH)
    GPIO.setup(SCK, GPIO.OUT, initial=GPIO.LOW)
    GPIO.setup(SO, GPIO.IN)


def read_temp(cs_no):
    GPIO.output(cs_no, GPIO.LOW)
    time.sleep(0.002)
    GPIO.output(cs_no, GPIO.HIGH)
    time.sleep(0.22)

    GPIO.output(cs_no, GPIO.LOW)
    GPIO.output(sck, GPIO.HIGH)
    time.sleep(0.001)
    GPIO.output(sck, GPIO.LOW)
    Value = 0
    for i in range(11, -1, -1):
        GPIO.output(sck, GPIO.HIGH)
        Value = Value + (GPIO.input(so) * (2**i))
        GPIO.output(sck, GPIO.LOW)

    GPIO.output(sck, GPIO.HIGH)
    error_tc = GPIO.input(so)
    GPIO.output(sck, GPIO.LOW)

    for i in range(2):
        GPIO.output(sck, GPIO.HIGH)
        time.sleep(0.001)
        GPIO.output(sck, GPIO.LOW)

    GPIO.output(cs_no, GPIO.HIGH)

    if unit == 0:
        temp = Value
    if unit == 1:
        temp = Value * 0.23
    if unit == 2:
        temp = Value * 0.23 * 9.0 / 5.0 + 32.0

    if error_tc != 0:
        return -cs_no
    else:
        return temp


class hil_gpio:
    def __init__(self) -> None:
        GPIO.setmode(GPIO.BOARD)
        GPIO.setwarnings(False)

    def read_temp(self, cs=26, sck=23, so=21):
        set_pin(cs, sck, so, 1)
        a = read_temp(cs)
        return a

    def __del__():
        GPIO.cleanup()