import sys
sys.path.append("../../")
import socket
from struct import error, pack
import time
from ctypes import *
from typing import Tuple
from api import Header, Packet



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
