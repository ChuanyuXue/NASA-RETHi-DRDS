import socket
from struct import pack
import random
from ctypes import *

IP_SERVER = "127.0.0.1"    ## Destination IP, referring server_configuration.json
PORT_SERVER = 10001       ## Destination Port, referring server_configuration.json

IP_CLIENT = "127.0.0.1" 
PORT_CLIENT = 10002

## Packet format referring packet.go
class Header(Structure):
    _fields_ = [
        ("opt", c_uint8),
        ("src", c_uint8),
        ("dst", c_uint8),
        ("type", c_uint8),
        ("param", c_uint8),
        ("priority", c_uint8),
        ("row", c_uint8),
        ("col", c_uint8),
        ("length", c_uint16),
        ("time", c_uint32)
    ]

class Packet:
    def __init__(self):
        pass
    
    # payload is a double list
    def pkt2Buf(self, _opt, _src, _dst, _type, _param, _priority, _row, _col, _length, _time, _payload):
        header_buf = Header(_opt, _src, _dst, _type, _param, _priority, _row, _col, _length, _time)
        double_arr = c_double * _length
        payload_buf = double_arr(*_payload)
        buf = bytes(header_buf)+bytes(payload_buf)
        return buf
        
    def buf2Pkt(self, buffer):
        self.header = Header.from_buffer_copy(buffer[:16])
        double_arr = c_double * self.header.length
        self.payload = double_arr.from_buffer_copy(buffer[16:16 + 8*self.header.length])
        return self.header._fields_
        
# ------------------------- API usage ----------------------------------
# 
## !!! First make sure IP address and Port of client is registered in server_configuration.json

    # "clients" : ["127.0.0.1"],
    # "clients_port" : ["10002"],
    # "clients_src" : ["1"]

## 1. Send() API
out_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
_opt = 0    ## _opt = 0 when send data
_src = 1    ## _src defined by "clients_src" in configuration file
_dst = 0    ## _dst defined by "src" in configuration file
_type = 1   ## _type is the type of sending data(FDD / Sensor) [when _opt = 0]
_param = 4  ## _param is the id of table [when _opt = 0]
_priority = 7   ## _priority [when _opt = 0]
_row = 1    ## _row [when _opt = 0]
_col = 3    ## _col [when _opt = 0]
_length = 3 ## _length = _row * _col [when _opt = 0]
_time = None   ## _time is Synchrounous time of sending[when _opt = 0]

## Simulate a continious sequence with synchrounous time
synchrounous_time = [1,2,3,4,5,6,7,8,9,10]
fake_sequence = [random.random() for i in range(10)]

for i, t in enumerate(synchrounous_time):
    _payload = [fake_sequence[i]]
    _time = t

    pkt = Packet()
    buf = pkt.pkt2Buf(_opt, _src, _dst, _type, _param, _priority,
                      _row, _col, _length, _time, _payload)
    out_sock.sendto(buf, (IP_SERVER, PORT_SERVER))
    pkt.buf2Pkt(buf)

## 2. Request() API
## First open bind with the server UDP channel
in_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
in_sock.bind((IP_CLIENT, PORT_CLIENT))
in_sock.setblocking(False)

### 2.1 Request by timestamp
_opt = 1    ## _opt = 1 when request data
_src = 1    ## _src defined by "clients_src" in configuration file
_dst = 0    ## _dst defined by "src" in configuration file
_type = 1   ## Nonsense [when _opt = 1]
_param = 4  ## _param is the id of table [when _opt = 1]
_priority = 7   ## Nonsense [when _opt = 1]
_row = 1    ## Nonsense [when _opt = 1]
_col = 3    ## Nonsense [when _opt = 1]
_length = 1 ## length = 1 by timestamp, length > 1 by timerange
_time = None   ## _time is retrieving time / timestart [when _opt = 1]

_payload = []
_time = 1

pkt = Packet()
buf = pkt.pkt2Buf(_opt, _src, _dst, _type, _param, _priority,
                    _row, _col, _length, _time, _payload)
out_sock.sendto(buf, (IP_SERVER, PORT_SERVER))

while True:
    try:
        message, _ = in_sock.recvfrom(65536 + 18)
        break
    except:
        pass
    
pkt.buf2Pkt(message)
print(list(pkt.payload))



