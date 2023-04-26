import socket
import struct
import ctypes
import time

# IP address and port number of the receiver
receiver_ip = '192.168.10.101'
receiver_port = 54113



# Create a UDP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# Pack the double number into binary format
count = 0
while True:
    count += 1
    packed_number = struct.pack('d', count)
    sock.sendto(packed_number, (receiver_ip, receiver_port))
    time.sleep(0.1)


# number_2 = 9
# c_double_number = ctypes.c_double(number)

# # Create a buffer from the c_double number
# buffer = ctypes.string_at(ctypes.pointer(c_double_number), ctypes.sizeof(c_double_number))

# # Send the buffer to the specified IP and port
# sock.sendto(buffer, (receiver_ip, receiver_port))



# Close the socket
sock.close()