"""
Basic utilities for the API

Author:
    Jiachen Wang
    Chuanyue Xue
    Murali Krishnan Rajasekharan Pillai

Date:
    01.18.2022
"""

from ctypes import *


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
        ("option", c_uint16),
        ("flag", c_uint16),
        ("param", c_uint16),
        ("subparam", c_uint16),
    ]


class Packet:

    def __init__(self):
        pass

    # payload is a double list
    def pkt2Buf(self, _src, _dst, _message_type, _data_type, _priority,
                _physical_time, _simulink_time, _row, _col, _length, _opt,
                _flag, _param, _subparam, _payload):
        temp = _message_type << 12 + _data_type << 4 + _priority
        header_buf = Header(_src, _dst, temp, _physical_time, _simulink_time,
                            _row, _col, _length, _opt, _flag, _param,
                            _subparam)
        double_arr = c_double * _length
        payload_buf = double_arr(*_payload)
        buf = bytes(header_buf) + bytes(payload_buf)
        return buf

    def buf2Pkt(self, buffer):
        self.header = Header.from_buffer_copy(buffer[:24])
        double_arr = c_double * self.header.length
        self.payload = double_arr.from_buffer_copy(
            buffer[24:24 + 8 * self.header.length])
        return self.header._fields_

    def pkt2dict(self, ):
        data = {}

        data["src"] = self.header.src
        data["dst"] = self.header.dst
        data["type"] = self.header.type
        data["physical_time"] = self.header.physical_time
        data["simulink_time"] = self.header.simulink_time
        data["row"] = self.header.row
        data["col"] = self.header.col
        data["length"] = self.header.length
        data["option"] = self.header.option
        data["flag"] = self.header.flag
        data["param"] = self.header.param
        data["subparam"] = self.header.subparam
        data["data"] = list(self.payload)

        return data
