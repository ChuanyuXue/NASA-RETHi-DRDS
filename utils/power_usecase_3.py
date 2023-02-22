# 0x5F Read input voltage, current, power and relative state
# Byte
# offset Meaning
# 3 to 6 4 byte little-endian integer for terminal voltage in units of 1 mV
# 7 to 10 4 byte little-endian integer for terminal current in units of 0.1 mA
# 11 to 14 4 byte little-endian integer for terminal power in units of 1 mW
# 15 Operation state register (see bit list below)
# 16 to 17 2 byte little-endian integer for demand state register (see bit list below)
# 18-24 Reserved

import serial
import time
import datetime

REMOTE_IP = "0.0.0.0"
REMOTE_PORT = 12345

LENGTH_PKT = 26

def checksum(data):
    return sum(data) & 0xff

cmd = []
cmd += [0xaa, 0x00, 0x20, 0x01]
cmd +=  [0x00] * (LENGTH_PKT - 4 - 1)
cmd += [checksum(cmd)]

assert len(cmd) == LENGTH_PKT

# print(len(cmd))
# print([hex(x) for x in cmd])


# ser = serial.Serial("/dev/ttyUSB0", 9600, parity=serial.PARITY_NONE,
#         stopbits=serial.STOPBITS_ONE, bytesize=serial.EIGHTBITS)
# ser.setDTR(False)
# ser.setRTS(False)

ser = serial.Serial()
ser.baudrate = 19200
ser.port = "/dev/ttyUSB0"
ser.open()
print(ser.is_open)

ser.write(cmd)

print([hex(x) for x in cmd])

response = ser.read(LENGTH_PKT)
print(response)
print(ser.is_open)

