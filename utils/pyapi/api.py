"""
Body of the API

Author:
    Chuanyu Xue
    Murali Krishnan Rajasekharan Pillai

Date:
    01.18.2022
"""

import time
import socket
from typing import Tuple

from pyapi.utils import *


class API:
    """
    The API object for communicating with the Communication and Data-
    Handling System (CDHS)

    """

    def __init__(self,
                 local_ip,
                 local_port,
                 to_ip,
                 to_port,
                 client_id=1,
                 server_id=0):

        self.id_client = client_id
        self.id_server = server_id
        self.ip_client = local_ip
        self.ip_server = to_ip
        self.port_client = local_port
        self.port_server = to_port

        self.out_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.in_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.in_sock.bind((self.ip_client, self.port_client))
        self.in_sock.setblocking(False)

        self.seq = 0

    def send(self, id, synt, value, priority=7):
        """
        Send packets (??)

        Parameters:
        -----------
        id          :
            ??
        synt        :
            ??
        value       :
            ??
        priority    :
            ??
        type        :
            ??
        """

        _src = self.id_client
        _dst = self.id_server
        _message_type = 1
        _priority = priority
        _verson = 0
        _reserved = 0
        _physical_time = int(time.time())
        _simulink_time = synt
        _sequence = self.seq
        _length = SERVICE_HEADER_LEN + SUB_HEADER_LEN + len(value) * 8

        _service = 0
        _flag = 0
        _opt1 = 0
        _opt2 = 0
        _subframe = 1

        _data_id = id
        _timediff = 0

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

        subpkt = SubPacket()
        subpkt.init(_data_id, _timediff, _row, _col, _length, _payload)

        pkt = Packet()

        pkt.init(
            _src,
            _dst,
            _message_type,
            _priority,
            _verson,
            _reserved,
            _physical_time,
            _simulink_time,
            _sequence,
            _length,
            _service,
            _flag,
            _opt1,
            _opt2,
            _subframe,
            [subpkt],
        )

        buf = pkt.pkt2Buf()
        self.out_sock.sendto(buf, (self.ip_server, self.port_server))

    def request(self, id, synt, priority=7):
        """
        Request information from data-repository

        Parameters:
        -----------
        id          :
            ??
        synt        :
            ??
        priority    :
            ??
        """

        _src = self.id_client
        _dst = self.id_server
        _message_type = 1
        _priority = priority
        _verson = 0
        _reserved = 0
        _physical_time = int(time.time())
        _sequence = self.seq
        _length = SERVICE_HEADER_LEN + SUB_HEADER_LEN

        _service = 1
        _flag = 0
        _opt1 = 0
        _opt2 = 0
        _subframe = 1

        _data_id = id
        _timediff = 0

        if not isinstance(synt, tuple):

            _timediff = 0
            _payload = []
            _simulink_time = synt
            _row = 0
            _col = 0
            _length = 0
            subpkt = SubPacket()
            subpkt.init(_data_id, _timediff, _row, _col, _length, _payload)
        else:
            _timediff = synt[1]
            _payload = []
            _simulink_time = synt[0]
            _row = 0
            _col = 0
            _length = 0
            subpkt = SubPacket()
            subpkt.init(_data_id, _timediff, _row, _col, _length, _payload)

        pkt = Packet()

        pkt.init(
            _src,
            _dst,
            _message_type,
            _priority,
            _verson,
            _reserved,
            _physical_time,
            _simulink_time,
            _sequence,
            _length,
            _service,
            _flag,
            _opt1,
            _opt2,
            _subframe,
            [subpkt],
        )

        buf = pkt.pkt2Buf()
        self.out_sock.sendto(buf, (self.ip_server, self.port_server))

        count = 0
        while True:
            if count > 1e3:
                return None
            try:
                message, _ = self.in_sock.recvfrom(65536)
                pkt.buf2Pkt(message)
                return pkt
            except:
                time.sleep(0.001)
                count += 1
                continue

    def publish_register(self, id, synt, priority=7):
        """
        Publish what (??)

        Parameters
        ----------
        id          :
            ??
        synt        :
            ??
        priority    :
            ??
        """
        _src = self.id_client
        _dst = self.id_server
        _message_type = 1
        _priority = priority
        _verson = 0
        _reserved = 0
        _physical_time = int(time.time())
        _simulink_time = synt
        _sequence = self.seq
        _length = SERVICE_HEADER_LEN + SUB_HEADER_LEN

        _service = 2
        _flag = 0
        _opt1 = 0
        _opt2 = 0
        _subframe = 1

        _data_id = id
        _timediff = 0
        _row = 0
        _col = 0
        _length = 0
        _payload = []

        subpkt = SubPacket()
        subpkt.init(_data_id, _timediff, _row, _col, _length, _payload)

        pkt = Packet()
        pkt.init(
            _src,
            _dst,
            _message_type,
            _priority,
            _verson,
            _reserved,
            _physical_time,
            _simulink_time,
            _sequence,
            _length,
            _service,
            _flag,
            _opt1,
            _opt2,
            _subframe,
            [subpkt],
        )
        buf = pkt.pkt2Buf()
        self.out_sock.sendto(buf, (self.ip_server, self.port_server))

        count = 0
        while True:
            if count > 1e3:
                return None
            try:
                message, _ = self.in_sock.recvfrom(65536)
                pkt.buf2Pkt(message)
                return pkt
            except:
                time.sleep(0.001)
                count += 1
                continue

    def publish(self, id, synt, value, priority=7):
        self.send(id, synt, value, priority)

    def subscribe_register(self, id, synt, priority=7):
        """
        Request to subscribe to a data-id from DRDS

        - Returns the ACK packet from DRDS if successful
        - Returns None if failed
        """
        _src = self.id_client
        _dst = self.id_server
        _message_type = 1
        _priority = priority
        _verson = 0
        _reserved = 0
        _physical_time = int(time.time())
        _simulink_time = synt
        _sequence = self.seq
        _length = SERVICE_HEADER_LEN + SUB_HEADER_LEN

        _service = 3
        _flag = 0
        _opt1 = 0
        _opt2 = 0
        _subframe = 1

        _data_id = id
        _timediff = 0
        _row = 0
        _col = 0
        _length = 0
        _payload = []

        subpkt = SubPacket()
        subpkt.init(_data_id, _timediff, _row, _col, _length, _payload)

        pkt = Packet()
        pkt.init(
            _src,
            _dst,
            _message_type,
            _priority,
            _verson,
            _reserved,
            _physical_time,
            _simulink_time,
            _sequence,
            _length,
            _service,
            _flag,
            _opt1,
            _opt2,
            _subframe,
            [subpkt],
        )
        buf = pkt.pkt2Buf()
        self.out_sock.sendto(buf, (self.ip_server, self.port_server))

        count = 0
        while True:
            if count > 1e3:
                return None
            try:
                message, _ = self.in_sock.recvfrom(65536)
                pkt.buf2Pkt(message)
                return pkt
            except:
                time.sleep(0.001)
                count += 1
                continue

    def subscribe(self, ):
        """
        Subscribe a data-id from DRDS

        - Returns the data packet from DRDS if successful
        - Returns None if time out
        """
        pkt = Packet()
        count = 0
        while True:
            if count > 1e3:
                return None
            try:
                message, _ = self.in_sock.recvfrom(65536)
                pkt.buf2Pkt(message)
                return pkt
            except:
                time.sleep(0.001)
                count += 1
                continue

    def close(self):
        """
        Close the sockets.
        """
        self.in_sock.close()
        self.out_sock.close()
