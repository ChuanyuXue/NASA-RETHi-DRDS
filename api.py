import socket
from struct import pack
import time
from ctypes import *
from typing import Tuple

from numpy import cdouble, uint, uint8

IP_SERVER = "127.0.0.1"  # Destination IP, referring server_configuration.json
PORT_SERVER = 10001  # Destination Port, referring server_configuration.json
ID_SERVER = 0

IP_CLIENT = "127.0.0.1"
PORT_CLIENT = 10002
ID_CLIENT = 1


class Header(BigEndianStructure):
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
        header_buf = Header(_src, _dst, temp, _physical_time, _simulink_time,
                            _row, _col, _length, _opt, _flag, _param, _subparam)
        double_arr = c_double * _length
        payload_buf = double_arr(*_payload)
        buf = bytes(header_buf)+bytes(payload_buf)
        return buf

    def buf2Pkt(self, buffer):
        self.header = Header.from_buffer_copy(buffer[:24])
        double_arr = c_double * self.header.length
        self.payload = double_arr.from_buffer_copy(
            buffer[24:24 + 8*self.header.length])
        return self.header._fields_

    def get_values(self, buffer):
        values = {}
        values["src"] = c_uint8.from_buffer_copy(buffer[0:1]).value
        values["dst"] = c_uint8.from_buffer_copy(buffer[1:2]).value
        temp = c_uint16.from_buffer_copy(buffer[2:4][::-1]).value

        values["message_type"] = temp // 2**12
        values["data_type"] = (temp // 2**4) % 2 ** 8
        values["priority"] = temp % 2**4

        values["physical_time"] = c_uint32.from_buffer_copy(
            buffer[4:8][::-1]).value
        values["simulink_time"] = c_uint32.from_buffer_copy(
            buffer[8:12][::-1]).value
        values["row"] = c_uint8.from_buffer_copy(buffer[12:13]).value
        values["col"] = c_uint8.from_buffer_copy(buffer[13:14]).value
        values["length"] = c_uint16.from_buffer_copy(buffer[14:16][::-1]).value
        values["opt"] = c_uint16.from_buffer_copy(buffer[16:18][::-1]).value
        values["flag"] = c_uint16.from_buffer_copy(buffer[18:20][::-1]).value
        values["param"] = c_uint16.from_buffer_copy(buffer[20:22][::-1]).value
        values["subparam"] = c_uint16.from_buffer_copy(
            buffer[22:24][::-1]).value

        payload = []
        for i in range(values["length"]):
            payload.append(c_double.from_buffer_copy(buffer[24+i*8: 24+i*8+8]))
        values["data"] = payload
        return values


def init(local_ip, local_port, to_ip, to_port, client_id=1, server_id=0):
    global ID_CLIENT
    global ID_SERVER
    global IP_CLIENT
    global IP_SERVER
    global PORT_CLIENT
    global PORT_SERVER
    global OUT_SOCK
    global IN_SOCK

    ID_CLIENT = client_id
    ID_SERVER = server_id
    IP_CLIENT = local_ip
    IP_SERVER = to_ip
    PORT_CLIENT = local_port
    PORT_SERVER = to_port

    OUT_SOCK = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    IN_SOCK = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    IN_SOCK.bind((IP_CLIENT, PORT_CLIENT))
    IN_SOCK.setblocking(False)


def send(id, synt, value, priority=7, type=1):
    global ID_CLIENT
    global ID_SERVER
    global IP_CLIENT
    global IP_SERVER
    global PORT_CLIENT
    global PORT_SERVER

    _src = ID_CLIENT
    _dst = ID_SERVER
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
    buf = pkt.pkt2Buf(_src, _dst, _message_type, _data_type, _priority, _physical_time,
                      _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam, _payload)
    OUT_SOCK.sendto(buf, (IP_SERVER, PORT_SERVER))


def request(id, synt, priority=7):
    global ID_CLIENT
    global ID_SERVER
    global IP_CLIENT
    global IP_SERVER
    global PORT_CLIENT
    global PORT_SERVER

    if not isinstance(synt, tuple):
        _src = ID_CLIENT
        _dst = ID_SERVER
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
        buf = pkt.pkt2Buf(_src, _dst, _message_type, _data_type, _priority, _physical_time,
                          _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam, _payload)
        OUT_SOCK.sendto(buf, (IP_SERVER, PORT_SERVER))
    else:
        _src = ID_CLIENT
        _dst = ID_SERVER
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
        buf = pkt.pkt2Buf(_src, _dst, _message_type, _data_type, _priority, _physical_time,
                          _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam, _payload)
        OUT_SOCK.sendto(buf, (IP_SERVER, PORT_SERVER))

    while True:
        try:
            message, _ = IN_SOCK.recvfrom(65536)
            return pkt.get_values(message)
        except:
            continue


def publish_register(id, synt, priority=7):
    _src = ID_CLIENT
    _dst = ID_SERVER
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
    buf = pkt.pkt2Buf(_src, _dst, _message_type, _data_type, _priority, _physical_time,
                      _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam, _payload)
    OUT_SOCK.sendto(buf, (IP_SERVER, PORT_SERVER))

    while True:
        try:
            message, _ = IN_SOCK.recvfrom(65536)
            return pkt.get_values(message)
        except:
            pass


def publish(id, synt, value, priority=7, type=1):
    _src = ID_CLIENT
    _dst = ID_SERVER
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
    buf = pkt.pkt2Buf(_src, _dst, _message_type, _data_type, _priority, _physical_time,
                      _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam, _payload)
    OUT_SOCK.sendto(buf, (IP_SERVER, PORT_SERVER))


def subscribe_register(id, synt, priority=7):
    _src = ID_CLIENT
    _dst = ID_SERVER
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
    buf = pkt.pkt2Buf(_src, _dst, _message_type, _data_type, _priority, _physical_time,
                      _simulink_time, _row, _col, _length, _opt, _flag, _param, _subparam, _payload)
    OUT_SOCK.sendto(buf, (IP_SERVER, PORT_SERVER))

    while True:
        try:
            message, _ = IN_SOCK.recvfrom(65536)
            return pkt.get_values(message)
        except:
            continue


def subscribe(id):
    pkt = Packet()

    while True:
        try:
            message, _ = IN_SOCK.recvfrom(65536)
            return pkt.get_values(message)
        except:
            continue


def close():
    IN_SOCK.close()
    OUT_SOCK.close()
