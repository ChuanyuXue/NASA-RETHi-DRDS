"""
Basic utilities for the API

Author:
    Jiachen Wang
    Chuanyue Xue
    Murali Krishnan Rajasekharan Pillai

Date:
    01.18.2022
"""

from calendar import c
from ctypes import *


class Header(LittleEndianStructure):
    _fields_ = [
        ("src", c_uint8),
        ("dst", c_uint8),
        ("type_prio", c_uint8),
        ("ver_res", c_uint8),
        ("physical_time", c_uint32),
        ("simulink_time", c_uint32),
        ("sequence", c_uint16),
        ("length", c_uint16),
        ("service", c_uint8),
        ("flag", c_uint8),
        ("option1", c_uint8),
        ("option2", c_uint8),
        ("subframe_num", c_uint16),
    ]


class SubHeader(LittleEndianStructure):
    _field_ = [("data_id", c_uint16), ("time_diff", c_uint16),
               ("row", c_uint8), ("col", c_uint8), ("length", c_uint16)]


class SubPacket:

    def __init__(self):
        pass

    def pkt2Buf(self, _data_id, _time_diff, _row, _col, _length, _payload):
        header_buf = SubHeader(
            _data_id,
            _time_diff,
            _row,
            _col,
            _length,
        )
        double_arr = c_double * _length
        payload_buf = double_arr(*_payload)
        buf = bytes(header_buf) + bytes(payload_buf)
        return buf

    def buf2Pkt(self, buffer):
        self.header = SubHeader.from_buffer_copy(buffer[:8])
        double_arr = c_double * self.header.length
        self.payload = double_arr.from_buffer_copy(
            buffer[8:8 + 8 * self.header.length])
        return self.header._fields_


class Packet:

    def __init__(self):
        pass

    # payload is a double list
    def pkt2Buf(self, _src, _dst, _type, _prio, _version, _reserved,
                _physical_time, _simulink_time, _sequence, _length, _service,
                _flag, _option1, _option2, _subframe_num, _subpackets):

        _type_prio = _type << 4 + _prio
        _ver_res = _version << 4 + _reserved
        header_buf = Header(_src, _dst, _type_prio, _ver_res, _version,
                            _reserved, _physical_time, _simulink_time,
                            _sequence, _length, _service, _flag, _option1,
                            _option2, _subframe_num)
        _
        return buf

    def buf2Pkt(self, buffer):
        self.header = Header.from_buffer_copy(buffer[:24])
        double_arr = c_double * self.header.length
        self.payload = double_arr.from_buffer_copy(
            buffer[24:24 + 8 * self.header.length])
        return self.header._fields_

        # def pkt2dict(self, ):
        #     data = {}

        #     data["src"] = self.header.src
        #     data["dst"] = self.header.dst
        #     data["type"] = self.header.type
        #     data["physical_time"] = self.header.physical_time
        #     data["simulink_time"] = self.header.simulink_time
        #     data["row"] = self.header.row
        #     data["col"] = self.header.col
        #     data["length"] = self.header.length
        #     data["option"] = self.header.option
        #     data["flag"] = self.header.flag
        #     data["param"] = self.header.param
        #     data["subparam"] = self.header.subparam
        #     data["data"] = list(self.payload)

        return data
