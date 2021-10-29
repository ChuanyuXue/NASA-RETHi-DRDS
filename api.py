import socket
from struct import pack
import time
from ctypes import *
from typing import Tuple

from numpy import uint, uint8

ip_server = "127.0.0.1"    ## Destination IP, referring server_configuration.json
port_server = 10001       ## Destination Port, referring server_configuration.json
id_server = 0

ip_client = "127.0.0.1" 
port_client = 10002
id_client = 1

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

    def get_values(self, buffer):
        values = []
        for i in range(8):
            values.append(c_uint8.from_buffer_copy(buffer[i:i+1]).value)
        values.append(c_uint16.from_buffer_copy(buffer[8:12]).value)
        length = values[-1]
        values.append(c_uint32.from_buffer_copy(buffer[12:16]).value)
        payload = []
        for i in range(length):
            payload.append(c_double.from_buffer_copy(buffer[16+i*8: 16+i*8 + 8]).value)
        values.append(payload)
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

def send(id, time, value, priority=7, type=1):
    global id_client
    global id_server
    global ip_client
    global ip_server
    global port_client
    global port_server

    _opt = 0    
    _src = id_client    
    _dst = id_server 
    _type = type   
    _param = id 
    _priority = priority  
    _time = time 

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
    buf = pkt.pkt2Buf(_opt, _src, _dst, _type, _param, _priority,
                    _row, _col, _length, _time, _payload)
    out_sock.sendto(buf, (ip_server, port_server))
    pkt.buf2Pkt(buf)




def request(id, time, priority = 7):
    global id_client
    global id_server
    global ip_client
    global ip_server
    global port_client
    global port_server

    if not isinstance(time, tuple):
        _opt = 1 
        _src = id_client 
        _dst = id_server
        _type = 0
        _param = id
        _priority = priority
        _row = 0
        _col = 0
        _length = 0
        _time = time
        _payload = []

        pkt = Packet()
        buf = pkt.pkt2Buf(_opt, _src, _dst, _type, _param, _priority,
                            _row, _col, _length, _time, _payload)
        out_sock.sendto(buf, (ip_server, port_server))
    else:
        _opt = 1 
        _src = id_client 
        _dst = id_server
        _type = 0
        _param = id
        _priority = priority
        _row = time[1]
        _col = 0
        _length = 0
        _time = time[0]
        _payload = []

        pkt = Packet()
        buf = pkt.pkt2Buf(_opt, _src, _dst, _type, _param, _priority,
                            _row, _col, _length, _time, _payload)
        out_sock.sendto(buf, (ip_server, port_server))

    while True:
        try:
            message, _ = in_sock.recvfrom(65536)
            return pkt.get_values(message)
        except:
            continue


def publish_register(id):
    _opt = 2 
    _src = id_client  
    _dst = id_server
    _type = 0
    _param = id
    _priority = 7 
    _length = 0
    _row = 0
    _col = 0 
    _time = 0
    _payload = []

    pkt = Packet()
    buf = pkt.pkt2Buf(_opt, _src, _dst, _type, _param, _priority,
                        _row, _col, _length, _time, _payload)
    out_sock.sendto(buf, (ip_server, port_server))

    while True:
        try:
            message, _ = in_sock.recvfrom(65536)

            return pkt.get_values(message)
        except:
            pass

 
def publish(id, time, value, priority = 7, type=1):
    _opt = 2 
    _src = id_client  
    _dst = id_server  
    _type = type
    _param = 4  
    _priority = priority
    _time = time

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
    buf = pkt.pkt2Buf(_opt, _src, _dst, _type, _param, _priority,
                    _row, _col, _length, _time, _payload)
    out_sock.sendto(buf, (ip_server, port_server))


def subscribe_register(id, time):
    _opt = 3 
    _src = id_client  
    _dst = id_server  
    _type = 0
    _param = id
    _priority = 7 
    _length = 0
    _row = 0
    _col = 0 
    _time = time
    _payload = []

    pkt = Packet()
    buf = pkt.pkt2Buf(_opt, _src, _dst, _type, _param, _priority,
                        _row, _col, _length, _time, _payload)
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
            values = pkt.get_values(message)
            if values[0] == 3 and values[4] == id:
                return values
            else:
                time.sleep(0.1)
                out_sock.sendto(message, (ip_client, port_client))
        except:
            continue
        