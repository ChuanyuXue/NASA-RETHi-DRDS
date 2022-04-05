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

from pyapi.utils import Header
from pyapi.utils import Packet


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
        self.in_sock.setblocking(True)

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
        buf = pkt.pkt2Buf(_src, _dst, _message_type, _data_type, _priority,
                          _physical_time, _simulink_time, _row, _col, _length,
                          _opt, _flag, _param, _subparam, _payload)
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
        _data_type = 0
        _priority = priority
        _physical_time = int(time.time())
        _row = 0
        _col = 0
        _length = 0

        _opt = 1
        _flag = 0
        _param = id

        if not isinstance(synt, tuple):

            _subparam = 1
            _payload = []
            _simulink_time = synt

            pkt = Packet()
            buf = pkt.pkt2Buf(_src, _dst, _message_type, _data_type, _priority,
                              _physical_time, _simulink_time, _row, _col,
                              _length, _opt, _flag, _param, _subparam,
                              _payload)
            self.out_sock.sendto(buf, (self.ip_server, self.port_server))
        else:
            _subparam = synt[1]
            _payload = []
            _simulink_time = synt[0]

            pkt = Packet()
            buf = pkt.pkt2Buf(_src, _dst, _message_type, _data_type, _priority,
                              _physical_time, _simulink_time, _row, _col,
                              _length, _opt, _flag, _param, _subparam,
                              _payload)
            self.out_sock.sendto(buf, (self.ip_server, self.port_server))

        count = 0
        while True:
            if count > 1e3:
                print("[!] Request time out")
                return Packet()
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
        buf = pkt.pkt2Buf(_src, _dst, _message_type, _data_type, _priority,
                          _physical_time, _simulink_time, _row, _col, _length,
                          _opt, _flag, _param, _subparam, _payload)
        self.out_sock.sendto(buf, (self.ip_server, self.port_server))

        count = 0
        while True:
            if count > 1e3:
                print("[!] Request time out")
                return Packet()
            try:
                message, _ = self.in_sock.recvfrom(65536)
                pkt.buf2Pkt(message)
                return pkt
            except:
                time.sleep(0.001)
                count += 1
                continue

    def publish(self, id, synt, value, priority=7, type=1):
        """
        Publish (??)

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
        """

        _src = self.id_client
        _dst = self.id_server
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
        buf = pkt.pkt2Buf(_src, _dst, _message_type, _data_type, _priority,
                          _physical_time, _simulink_time, _row, _col, _length,
                          _opt, _flag, _param, _subparam, _payload)
        self.out_sock.sendto(buf, (self.ip_server, self.port_server))

    def subscribe_register(self, id, synt, priority=7):
        """
        Subscribe register

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
        buf = pkt.pkt2Buf(_src, _dst, _message_type, _data_type, _priority,
                          _physical_time, _simulink_time, _row, _col, _length,
                          _opt, _flag, _param, _subparam, _payload)
        self.out_sock.sendto(buf, (self.ip_server, self.port_server))

        count = 0
        while True:
            if count > 1e3:
                print("[!] Request time out")
                return Packet()
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
        Subscribe for information

        Parameters:
        -----------
        id          :       int
            ??
        """
        pkt = Packet()
        count = 0
        while True:
            if count > 1e3:
                print("[!] Request time out")
                return Packet()
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
