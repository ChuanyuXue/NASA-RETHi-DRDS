## This code is for the NAGNA-POWER ALx Series Powerload
## Communication follows TCP protocol
## https://magna-power.com/assets/docs/html_alx/index-scpi.html#scpi2-configuration-control-mode

import socket
import time

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
flag = s.connect(("192.168.10.98", 50505))

s.sendall('INP:START\n'.encode())

# s.sendall('CONF:REST 1\n'.encode())

# time.sleep(0.1)
# s.sendall('VOLT:TRIG MAX\n'.encode())
# time.sleep(0.1)
# s.sendall('CURR:TRIG MAX\n'.encode())
# time.sleep(0.1)
# s.sendall('VOLT:PROT MAX\n'.encode())

# s.sendall('VOLT 1\n'.encode())
# time.sleep(0.1)
# s.sendall('CURR 1\n'.encode())
# time.sleep(0.1

time.sleep(0.1)
print("Into the loop")

while True:
    s.sendall('MEAS:VOLT?\n'.encode())
    volt = float(s.recv(4096).decode().strip())

    s.sendall('MEAS:CURR?\n'.encode())
    curr = float(s.recv(4096).decode().strip())

    print(f"Voltage: {volt:4.5f} V ---- Current: {curr:4.5f} A")
    time.sleep(1)
