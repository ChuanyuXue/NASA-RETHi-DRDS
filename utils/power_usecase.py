from pyapi.utils import Header, Packet
from ctypes import *
from struct import error, pack
import socket

LOCAL_IP = "0.0.0.0"
LOCAL_PORT = 50


try:
    sock = socket.socket(
        socket.AF_INET,  # Internet
        socket.SOCK_DGRAM)  # UDP
    sock.bind((LOCAL_IP, LOCAL_PORT))
except error:
    print(LOCAL_PORT, str(error))

log = {}

print("----------------- Start listening packets ------------------------")

while True:
    re = Packet()
    data, addr = sock.recvfrom(1500)  # buffer size is 1024 bytes
    re.buf2Pkt(data)
    print("Receive the packets from Simulink")
    for i in re.subpackets:
        # print(i.header.data_id)
        # print(i.header.col, i.header.row, i.header.length)
        # print(i.payload)
        
        # Check the command status and call the C program 
        pass
    
