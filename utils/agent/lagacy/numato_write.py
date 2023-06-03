import sys
import serial
import time

#Open port for communication	
serPort = serial.Serial('/dev/ttyACM0', 19200, timeout=1)

serPort.write("gpio iodir 00\r".encode())

# serPort.write("gpio set 6\r".encode())
# serPort.write("gpio clear 6\r".encode())

# serPort.write("gpio set 7\r".encode())
# serPort.write("gpio clear 7\r".encode())


#Close the port
serPort.close()