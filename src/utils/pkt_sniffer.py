import socket
from struct import pack
import time
from ctypes import *
from typing import Tuple
from ...api import Header, Packet

UDP_IP = "127.0.0.1"

for port in range(1025, 65536):
    sock = socket.socket(
        socket.AF_INET,  # Internet
        socket.SOCK_DGRAM
    )  # UDP
    sock.bind((UDP_IP, port))

while True:
    pkt = Packet()
    data, addr = sock.recvfrom(1024)  # buffer size is 1024 bytes
    pkt.get_values(data)
    print(pkt)
