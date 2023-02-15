## This program acts as a gateway on RaspberryPi for BK-PRECISION 85**
## It reads serial data
## and send the observation to simulink

from pyapi.utils import Header, Packet
from ctypes import *
from struct import error, pack
import subprocess
import socket

LOCAL_IP = "0.0.0.0"
LOCAL_PORT = 12345


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
    print(re.header.simulink_time)
    print("Receive the packets from Simulink")
    for i in re.subpackets:
        print(i.header.data_id)
        print(i.header.col, i.header.row, i.header.length)
        print(i.payload[0])
        
        subprocess.call(["./eth32/eth32-example/comm", str(0), str(i.payload[0])])

        # Check the command status and call the C program 
        pass
    
