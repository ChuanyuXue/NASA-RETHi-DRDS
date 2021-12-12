import sys
sys.path.append("../../")
from api import Header, Packet
from typing import Tuple
from ctypes import *
import time
from struct import error, pack
import socket



UDP_IP = "127.0.0.1"

for port in [10006]:
    try:
        sock = socket.socket(
            socket.AF_INET,  # Internet
            socket.SOCK_DGRAM
        )  # UDP
        sock.bind((UDP_IP, port))
    except error:
        print(port, str(error))

print("-----------------Start packet sniffing------------------------")
while True:
    pkt = Packet()
    data, addr = sock.recvfrom(1024)  # buffer size is 1024 bytes
    print(pkt.get_values(data))
