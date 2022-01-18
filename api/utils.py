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
    """
    Header information for each packet
    """
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
        ("Subparam", c_uint16)
    ]

class Packet:
    """
    Each packet transported through the communication network

    """
    def __init__(self):
        pass

    # payload is a list of ``double''
    def pkt2Buf(self, _src, _dst, 
        _message_type, 
        _data_type, 
        _priority,
        _physical_time,
        _simulink_time,
        _row,
        _col,
        _length,
        _opt,
        _flag,
        _param,
        _subparam,
        _payload):

        temp = _message_type << 12 + _data_type << 4 + _priority
        header_buf = Header(_src, _dst, temp,
            _physical_time,
            _simulink_time,
            _row,
            _col,
            _length,
            _opt,
            _flag,
            _param,
            _subparam)
        double_arr = c_double * _length
        payload_buf = double_arr(*_payload)
        buf = bytes(header_buf) + bytes(payload_buf)
        return buf

    def buf2Pkt(self, buffer):
        self.header = Header.from_buffer_copy(buffer[:24])
        double_arr = c_double * self.header.length
        self.payload = double_arr.from_buffer_copy(
            buffer[24:24 + 8 * self.header.length][::-1])[::-1]
        return self.header._fields_