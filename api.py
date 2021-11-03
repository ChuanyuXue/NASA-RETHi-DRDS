import socket
from struct import pack
import time
from ctypes import *
from typing import Tuple

from numpy import cdouble, uint, uint8

ip_server = "127.0.0.1"    ## Destination IP, referring server_configuration.json
port_server = 10001       ## Destination Port, referring server_configuration.json
id_server = 0

ip_client = "127.0.0.1" 
port_client = 10002
id_client = 1

class Header(Structure):
    _fields_ = [
        ("src", c_uint8),
        ("dst", c_uint8),
        ("type", c_uint16),
        ("physical_time", c_uint32),
        ("simulink_time", c_uint32),
        ("row", c_uint8),
        ("col", c_uint8),
        ("length", c_uint16),
        ("Option", c_uint16),
        ("Flag", c_uint16),
        ("Param", c_uint16),
        ("Subparam", c_uint16),
    ]




class Packet:
    def __init__(self):
        pass
    
    # payload is a double list
    def pkt2Buf(self, _src, _dst, _message_type, _data_type, _priority, _physical_time, _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam, _payload):
        temp = _message_type << 12 + _data_type << 4 + _priority
        header_buf = Header(_src, _dst, temp, _physical_time, _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam)
        double_arr = c_double * _length
        payload_buf = double_arr(*_payload)
        buf = bytes(header_buf)+bytes(payload_buf)
        return buf
        
    def buf2Pkt(self, buffer):
        self.header = Header.from_buffer_copy(buffer[:24])
        double_arr = c_double * self.header.length
        self.payload = double_arr.from_buffer_copy(buffer[24:24 + 8*self.header.length])
        return self.header._fields_

    def get_values(self, buffer):
        values = {}
        values["src"] = c_uint8.from_buffer_copy(buffer[0:1]).value
        values["dst"] = c_uint8.from_buffer_copy(buffer[1:2]).value
        temp = c_uint16.from_buffer_copy(buffer[2:4]).value

        values["message_type"] = temp // 2**12
        values["data_type"] = (temp // 2**4) % 2 ** 8
        values["priority"] = temp % 2**4

        values["physical_time"] =  c_uint32.from_buffer_copy(buffer[4:8]).value
        values["simulink_time"] =  c_uint32.from_buffer_copy(buffer[8:12]).value
        values["row"] = c_uint8.from_buffer_copy(buffer[12:13]).value
        values["col"] = c_uint8.from_buffer_copy(buffer[13:14]).value
        values["length"] = c_uint16.from_buffer_copy(buffer[14:16]).value
        values["opt"] = c_uint16.from_buffer_copy(buffer[16:18]).value
        values["flag"] = c_uint16.from_buffer_copy(buffer[18:20]).value
        values["param"] = c_uint16.from_buffer_copy(buffer[20:22]).value
        values["subparam"] = c_uint16.from_buffer_copy(buffer[22:24]).value
        
        payload = []
        for i in range(values["length"]):
            payload.append(c_double.from_buffer_copy(buffer[24+i*8: 24+i*8+8]))
        values["data"] = payload
        return values

        

def init(client_ip, client_port, server_ip, server_port, client_id = 1, server_id=0):
    global id_client
    global id_server
    global ip_client
    global ip_server
    global port_client
    global port_server
    global out_sock
    global in_sock

    id_client = client_id
    id_server = server_id
    ip_client = client_ip
    ip_server = server_ip
    port_client = client_port
    port_server = server_port

    out_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    in_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    in_sock.bind((ip_client, port_client))
    in_sock.setblocking(False)

def send(id, synt, value, priority=7, type=1):
    global id_client
    global id_server
    global ip_client
    global ip_server
    global port_client
    global port_server


    _src = id_client
    _dst = id_server
    _message_type = 1
    _data_type = type
    _priority = priority
    _physical_time = int(time.time())
    _simulink_time = synt

    _opt = 0
    _flag = 0
    _param = id
    _subparam = 0

    if not isinstance(value[0], list):
        _payload = value
        _row = 1
        _col = len(value)
        _length = _col
    else:
        _payload = [x for y in value for x in y]
        _row = len(value)
        _col = len(value[0])
        _length = _row * _col

    pkt = Packet()
    buf = pkt.pkt2Buf( _src, _dst, _message_type, _data_type, _priority, _physical_time, _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam, _payload)
    out_sock.sendto(buf, (ip_server, port_server))
    pkt.buf2Pkt(buf)




def request(id, synt, priority = 7):
    global id_client
    global id_server
    global ip_client
    global ip_server
    global port_client
    global port_server

    if not isinstance(synt, tuple):
        _src = id_client
        _dst = id_server
        _message_type = 1
        _data_type = 0
        _priority = priority
        _physical_time = int(time.time())
        _simulink_time = synt
        _row = 0
        _col = 0
        _length = 0

        _opt = 1
        _flag = 0
        _param = id
        _subparam = 1

        _payload = []

        pkt = Packet()
        buf = pkt.pkt2Buf( _src, _dst, _message_type, _data_type, _priority, _physical_time, _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam, _payload)
        out_sock.sendto(buf, (ip_server, port_server))
    else:
        _src = id_client
        _dst = id_server
        _message_type = 1
        _data_type = 0
        _priority = priority
        _physical_time = int(time.time())
        _simulink_time = synt[0]
        _row = 0
        _col = 0
        _length = 0

        _opt = 1
        _flag = 0
        _param = id
        _subparam = synt[1]

        _payload = []

        pkt = Packet()
        buf = pkt.pkt2Buf( _src, _dst, _message_type, _data_type, _priority, _physical_time, _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam, _payload)
        out_sock.sendto(buf, (ip_server, port_server))

    while True:
        try:
            message, _ = in_sock.recvfrom(65536)
            return pkt.get_values(message)
        except:
            continue


def publish_register(id, synt, priority=7):
    _src = id_client
    _dst = id_server
    _message_type = 1
    _data_type = 0
    _priority = priority
    _physical_time = int(time.time())
    _simulink_time = synt
    _row = 0
    _col = 0
    _length = 0

    _opt = 2
    _flag = 0
    _param = id
    _subparam = 0

    _payload = []

    pkt = Packet()
    buf = pkt.pkt2Buf( _src, _dst, _message_type, _data_type, _priority, _physical_time, _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam, _payload)
    out_sock.sendto(buf, (ip_server, port_server))

    while True:
        try:
            message, _ = in_sock.recvfrom(65536)
            return pkt.get_values(message)
        except:
            pass

 
def publish(id, synt,value, priority = 7, type=1):
    _src = id_client
    _dst = id_server
    _message_type = 1
    _data_type = type
    _priority = priority
    _physical_time = int(time.time())
    _simulink_time = synt

    _opt = 2
    _flag = 1
    _param = id
    _subparam = 0

    if not isinstance(value[0], list):
        _payload = value
        _row = 1
        _col = len(value)
        _length = _col
    else:
        _payload = [x for y in value for x in y]
        _row = len(value)
        _col = len(value[0])
        _length = _row * _col

    pkt = Packet()
    buf = pkt.pkt2Buf( _src, _dst, _message_type, _data_type, _priority, _physical_time, _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam, _payload)
    out_sock.sendto(buf, (ip_server, port_server))



def subscribe_register(id, synt, priority=7):
    _src = id_client
    _dst = id_server
    _message_type = 1
    _data_type = 0
    _priority = priority
    _physical_time = int(time.time())
    _simulink_time = synt
    _row = 0
    _col = 0
    _length = 0

    _opt = 3
    _flag = 1
    _param = id
    _subparam = 0
    _payload = []


    pkt = Packet()
    buf = pkt.pkt2Buf( _src, _dst, _message_type, _data_type, _priority, _physical_time, _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam, _payload)
    out_sock.sendto(buf, (ip_server, port_server))

    while True:
        try:
            message, _ = in_sock.recvfrom(65536)
            return pkt.get_values(message)
        except:
            continue


def subscribe(id):
    pkt = Packet()

    while True:
        try:
            message, _ = in_sock.recvfrom(65536)
            return pkt.get_values(message)
        except:
            continue
        