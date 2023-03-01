## This program acts as a gateway on RaspberryPi for MEGNA POWER GENERATOR
## It writes serial data to request the current voltage 
## and read the serial response getting the current voltage
## https://magna-power.com/assets/files/manuals/manual_ts_1.0.pdf

import serial
import time
import datetime

from pyapi.api import API
from ctypes import *
import socket

REMOTE_IP = "192.168.0.96"
REMOTE_PORT = 12345

ins = API(local_ip="0.0.0.0",
              local_port=65533,
              to_ip=REMOTE_IP,
              to_port=REMOTE_PORT,
              client_id=1,
              server_id=6)
# count = 0
# while True:
#     print("Send the packets to Simulink")
#     ins.send(10001, count, [x + count for x in range(5)])
#     count += 1
#     time.sleep(1)

ser = serial.Serial("/dev/ttyUSB0", 19200, parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE, bytesize=serial.EIGHTBITS)
ser.timeout = 5
time.sleep(1)

print(ser.is_open)
ser.write(b'OUTP:START\n')
count = 0
while True:
    try:
        ser.write(b'MEAS:VOLT?\n')
        resp = ser.readline().decode()
        volt = eval(resp.replace('\n',''))
        print("%s -----> Current Volt: "%time.ctime(), volt)

        ser.write(b'MEAS:CURR?\n')
        resp = ser.readline().decode()
        curr = eval(resp.replace('\n',''))
        print("%s -----> Current Curr: "%time.ctime(), curr)

        ser.write(b'CAL:SCAL:VOLT?\n')
        resp = ser.readline().decode()
        cali_volt = eval(resp.replace('\n',''))
        print("%s -----> Current Calibration Volt: "%time.ctime(), cali_volt)

        ser.write(b'CAL:SCAL:CURR?\n')
        resp = ser.readline().decode()
        cali_curr = eval(resp.replace('\n',''))
        print("%s -----> Current Calibration Curr: "%time.ctime(), cali_curr)

        ins.send(10001, count, [volt, curr, cali_volt, cali_curr, 0])
        count += 1
        time.sleep(1)
    except KeyboardInterrupt:
        break
    except Exception as e:
        while not ser.is_open:
            ser = serial.Serial("/dev/ttyUSB0", 19200, parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE, bytesize=serial.EIGHTBITS)
            print("Serial Timeout Exception: ", e)
            print("Reopen the serial port")
            print("Exception: ", e)
            time.sleep(1)

ser.write(b'OUTP:STOP\n')
ser.close()