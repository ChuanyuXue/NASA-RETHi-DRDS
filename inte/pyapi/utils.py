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
from curses.ascii import SUB

HEADER_LEN = 16
SERVICE_HEADER_LEN = 6
SUB_HEADER_LEN = 8


class Header(Structure):
    _pack_ = 1
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


class SubHeader(Structure):
    _pack_ = 1
    _fields_ = [
        ("data_id", c_uint16),
        ("time_diff", c_uint16),
        ("row", c_uint8),
        ("col", c_uint8),
        ("length", c_uint16),
    ]


class SubPacket:

    def __init__(self, ):
        pass

    def init(self, _data_id, _time_diff, _row, _col, _length, _payload):
        self.header = SubHeader(
            _data_id,
            _time_diff,
            _row,
            _col,
            _length,
        )
        self.payload = _payload

    def pkt2Buf(self, ):
        double_arr = c_double * self.header.length
        payload_buf = double_arr(*self.payload)
        buf = bytes(self.header) + bytes(payload_buf)
        return buf

    def buf2Pkt(self, buffer):
        self.header = SubHeader.from_buffer_copy(buffer[:SUB_HEADER_LEN])
        double_arr = c_double * self.header.length
        self.payload = double_arr.from_buffer_copy(
            buffer[SUB_HEADER_LEN:SUB_HEADER_LEN + 8 * self.header.length])
        return SUB_HEADER_LEN + 8 * self.header.length


class Packet:

    def __init__(self, ):
        pass

    def init(self, _src, _dst, _type, _prio, _version, _reserved,
             _physical_time, _simulink_time, _sequence, _length, _service,
             _flag, _option1, _option2, _subframe_num, _subpackets):
        _type_prio = _type << 4 + _prio
        _ver_res = _version << 4 + _reserved
        self.header = Header(_src, _dst, _type_prio, _ver_res, _physical_time,
                             _simulink_time, _sequence, _length, _service,
                             _flag, _option1, _option2, _subframe_num)
        self.subpackets = _subpackets

    # payload is a double list
    def pkt2Buf(self, ):
        buf = bytes(self.header)
        for subpkt in self.subpackets:
            buf += subpkt.pkt2Buf()
        return buf

    def buf2Pkt(self, buffer):
        self.header = Header.from_buffer_copy(buffer[:HEADER_LEN +
                                                     SERVICE_HEADER_LEN])
        self.subpackets = []
        index = HEADER_LEN + SERVICE_HEADER_LEN

        for i in range(self.header.subframe_num):
            subpkt = SubPacket()
            index += subpkt.buf2Pkt(buffer[index:])
            self.subpackets.append(subpkt)

        return index


if __name__ == '__main__':
    pass
    ## ------------------- TEST FOR SINGLE SUBPACKET
    # subpkt = SubPacket()
    # subpkt.init(150, 0, 3, 1, 3, [1, 2, 3])

    # buf = subpkt.pkt2Buf()
    # subpkt_2 = SubPacket()
    # subpkt_2.buf2Pkt(buf)

    # print(subpkt.header.data_id)
    # print(subpkt_2.header.data_id)

    # print(subpkt.header.length)
    # print(subpkt_2.header.length)

    # print(subpkt.payload)
    # print(list(subpkt_2.payload))

    ## --------------------- TEST FOR ALL PACKETS

    # subpkt2 = SubPacket()
    # subpkt2.init(151, 0, 2, 2, 4, [1, 2, 3.5])

    # pkt = Packet()
    # pkt.init(0, 1, 0, 4, 0, 0, 123456, 654312, 0, 15, 0, 0, 0, 0, 2,
    #          [subpkt, subpkt2])

    # buff = pkt.pkt2Buf()

    # pkt2 = Packet()
    # pkt2.buf2Pkt(buff)

    # print(pkt.header.physical_time)
    # print(pkt2.header.physical_time)

    # print(pkt.subpackets[0].header.data_id)
    # print(pkt2.subpackets[0].header.data_id)

    # print(pkt.subpackets[0].header.length)
    # print(pkt2.subpackets[0].header.length)

    # print(pkt.subpackets[0].payload)
    # print(list(pkt2.subpackets[0].payload))