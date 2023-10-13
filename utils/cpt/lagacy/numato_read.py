import sys
import serial
import time

#Open port for communication	
serPort = serial.Serial('/dev/ttyACM1', 19200, timeout=1)

# Read adc
serPort.write("adc read 5\r".encode())

response = serPort.read(25).decode()

print(eval(response.split('\n')[1]) / 1023 * 5.2)

# serPort.write("adc read 5\r".encode())
# serPort.write("gpio iodir 00\r".encode())
# serPort.write("gpio writeall ff\r".encode())

# serPort.write(f"gpio set {i}\r".encode())
# for i in range(8):
#     # serPort.write(f"gpio clear {i}\r".encode())
#     serPort.write(f"gpio set {i}\r".encode())
#     time.sleep(1)

# while True:
#     # for i in range(8):
#     #     serPort.write(f"gpio read {i}\r".encode())
#     #     time.sleep(1)
#     #     response = serPort.read(128).decode()
#     serPort.write("gpio readall ff\r".encode())
#     time.sleep(1)
#     response = serPort.read(128).decode()
#     print(response)

#Close the port
serPort.close()