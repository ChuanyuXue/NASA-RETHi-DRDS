from pyapi.utils import Header, Packet
from ctypes import *
from struct import error, pack
import socket



UDP_IP = "127.0.0.1"

for port in [8001]:
    try:
        sock = socket.socket(
            socket.AF_INET,  # Internet
            socket.SOCK_DGRAM
        )  # UDP
        sock.bind((UDP_IP, port))
    except error:
        print(port, str(error))

log = {}

print("-----------------Start packet sniffing------------------------")
count = 0
while True:
    count += 1
    print('-----------------------')
    re = Packet()
    data, addr = sock.recvfrom(1024)  # buffer size is 1024 bytes
    re.buf2Pkt(data)
    for i in re.subpackets:
        # print(i.header.data_id)
        # print(i.header.col, i.header.row, i.header.length)
        log[i.header.data_id] = (i.header.col, i.header.row, i.header.length)
    if count > 100:
        break
for i in log:
    print(i,log[i])
