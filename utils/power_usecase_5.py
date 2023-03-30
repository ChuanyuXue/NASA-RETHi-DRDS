## This code is for the NAGNA-POWER ALx Series Powerload
## Communication follows TCP protocol

import socket
import time

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('192.168.0.98', 50505))

while True:
    s.sendall('MEAS:VOLT?\n'.encode())
    volt = float(s.recv(4096).decode().strip())

    s.sendall('MEAS:CURR?\n'.encode())
    curr = float(s.recv(4096).decode().strip())

    print(f"Voltage: {volt:4.5f} V ---- Current: {curr:4.5f} A")
    time.sleep(1)