## This program acts as a gateway on RaspberryPi for MEGAN POWER GENERATOR
## It writes serial data to request the current voltage 
## and read the serial response getting the current voltage

import serial
import time
import datetime

ser = serial.Serial("/dev/ttyUSB0", 19200, parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE, bytesize=serial.EIGHTBITS)

time.sleep(1)
print(ser.is_open)
ser.write(b'OUTP:START\n')
while True:
    try:
        ser.write(b'MEAS:VOLT?\n')
        resp = ser.readline().decode()
        print("%s -----> Current Volt: "%time.ctime(), resp.replace('\n',''))
        print("%s -----> Relay via UDP"%time.ctime())
        time.sleep(1)
    except KeyboardInterrupt:
        break

ser.write(b'OUTP:STOP\n')
ser.close()