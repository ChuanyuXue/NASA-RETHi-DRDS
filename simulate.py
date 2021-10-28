import socket
import time
import random

IP = "127.0.0.1"
PORT = 3333

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

from ctypes import *

class Header(Structure):
    _fields_ = [("src", c_uint8),
                ("dst", c_uint8),
                ("type", c_uint8),
                ("priority", c_uint8),
                ("row", c_uint8),
                ("col", c_uint8),
                ("col2", c_uint8),
                ("col3", c_uint8),
                ("length", c_uint16)]

class Packet:
    def __init__(self):
        pass
    
    # payload is a double list
    def pkt2Buf(self, _src, _dst, _type, _priority, _row, _col, _length, _payload):
        header_buf = Header(_src, _dst, _type, _priority, _row, _col, _length)
        double_arr = c_double * _length
        payload_buf = double_arr(*_payload)
        buf = bytes(header_buf)+bytes(payload_buf)
        return buf
        
    def buf2Pkt(self, buffer):
        self.header = Header.from_buffer_copy(buffer[:9])
        double_arr = c_double * self.header.length
        self.payload = double_arr.from_buffer_copy(buffer[9:9+8*self.header.length])

# usage:

cnt = 0
while True:
    # if cnt>10:
    #     break

    _src = 2
    _dst = 1
    _type = 3
    _priority = 7
    _row = 1
    _col = 3
    _length = 3
    # _payload = [
    #     1, UNDEFINED, UNDEFINED, UNDEFINED, UNDEFINED,
    #     3, 2, 1, 2, UNDEFINED,
    #     1, 2, 1, 1, 5,
    #     1, 2, 3, 2, 5,
    #     3, 2, 1, 1, UNDEFINED,
    #     UNDEFINED, UNDEFINED, UNDEFINED, UNDEFINED, UNDEFINED
    # ]
    _payload = [4, random.randint(0, 10), 0.1]
    pkt = Packet()
    buf = pkt.pkt2Buf(_src, _dst, _type, _priority,
                      _row, _col, _length, _payload)
    sock.sendto(buf, (IP, PORT))
    pkt.buf2Pkt(buf)
    print("[{}] sent {} bytes".format(cnt, len(buf)))
    time.sleep(0.1)
    # time.sleep(2)
    cnt += 1
    break