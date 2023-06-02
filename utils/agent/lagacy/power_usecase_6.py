## MAX6675
## pip install RPi.GPIO


import RPi.GPIO as GPIO
import time
GPIO.setmode(GPIO.BOARD)
GPIO.setwarnings(False)

# set pin number for communicate with MAX6675
def set_pin (CS, SCK, SO, UNIT):
    global sck
    sck= SCK
    global so
    so = SO
    global unit
    unit = UNIT
    
    GPIO.setup(CS, GPIO.OUT, initial = GPIO.HIGH)
    GPIO.setup(SCK, GPIO.OUT, initial = GPIO.LOW)
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
        Value = Value + (GPIO.input(so) * (2 ** i))
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

GPIO.cleanup()

# set the pin for communicate with MAX6675
cs = 26
sck = 23
so = 21
# max6675.set_pin(CS, SCK, SO, unit) [unit : 0 - raw, 1 - Celsius, 2 - Fahrenheit]
set_pin(cs, sck, so, 1)
try:
    while 1:
    # read temperature connected at CS 22
        a = read_temp(cs)
    # print temperature
        print (a)
    # when there are some errors with sensor, it return "-" sign and CS pin number
    # in this case it returns "-22"
        time.sleep(2)
except KeyboardInterrupt:
    pass
