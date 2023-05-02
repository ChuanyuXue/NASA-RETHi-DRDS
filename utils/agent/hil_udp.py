import struct
import socket
import sys


def get_send_socket():
    return socket.socket(socket.AF_INET, socket.SOCK_DGRAM)


def get_recv_socket(ip, port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((ip, port))
    return sock


def send(sock, ip, port, data):
    '''
    sock is like:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    '''
    packed_data = struct.pack('d' * len(data), *data)
    sock.sendto(packed_data, (ip, port))


def receive(sock, size=1):
    '''
    sock must be binded to a ip and port
    '''
    data, addr = sock.recvfrom(size * 8)
    result = []
    for i in range(size):
        result.append(struct.unpack('d', data[i * 8:(i + 1) * 8])[0])
    return result


if __name__ == '__main__':
    if sys.argv[1] == 's':
        send(get_send_socket(), "localhost", 54113, [1, 2, 3])
    elif sys.argv[1] == 'r':
        print(receive(get_recv_socket("localhost", 54113), 3))
