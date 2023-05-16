import struct
import socket
import sys
import time
from threading import Thread

def send(sock, ip, port, data):
    '''
    sock is like:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    '''
    packed_data = struct.pack('d' * len(data), *data)
    sock.sendto(packed_data, (ip, port))

class hil_udp(Thread):
    def __init__(self, local_ip, local_port):
        super().__init__()
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.bind((local_ip, local_port))
        self.buffer = []

    def receive(self, size=1):
        '''
        sock must be binded to a ip and port
        '''
        data, addr = self.sock.recvfrom(size * 8)
        result = []
        for i in range(size):
            result.append(struct.unpack('d', data[i * 8:(i + 1) * 8])[0])
        return result
    
    def _append_data(self, data):
        if len(self.buffer) > 1024:
            self.buffer = self.buffer[-1024:]
        self.buffer.append(data)
    
    def receive_latest(self):
        if len(self.buffer) == 0:
            return None
        data = self.buffer.pop()
        self.buffer = []
        return data

    def run(self, size = 1):
        while True:
            data = self.receive(size)
            self.buffer.append(data)

# def get_send_socket():
#     return socket.socket(socket.AF_INET, socket.SOCK_DGRAM)


# def get_recv_socket(ip, port):
#     sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
#     sock.bind((ip, port))
#     return sock


if __name__ == '__main__':
    # if sys.argv[1] == 's':
    #     send(get_send_socket(), "localhost", 54113, [1, 2, 3])
    # elif sys.argv[1] == 'r':
    #     print(receive(get_recv_socket("localhost", 54113), 3))

    listenr = hil_udp("0.0.0.0", 10003)
    listenr.start()
    while True:
        print(listenr.receive_latest())
        time.sleep(0.5)




