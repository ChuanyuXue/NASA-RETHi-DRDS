## This code is for the PZEM-003/017 DC communication module

import serial
import time
import datetime

## Communication configurations
BAUD_RATE = 9600
BYTE_SIZE = serial.EIGHTBITS
STOP_BIT = serial.STOPBITS_TWO
PARITY = serial.PARITY_NONE

def calculate_crc(data):
    # The ModbusRTU CRC is a 16-bit value calculated over the entire packet,
    # excluding the CRC itself. The polynomial used is x^16 + x^15 + x^2 + 1.
    # This function implements the CRC calculation algorithm.
    
    crc = 0xFFFF
    for byte in data:
        crc ^= byte
        for _ in range(8):
            if crc & 0x0001:
                crc >>= 1
                crc ^= 0xA001
            else:
                crc >>= 1
    return crc.to_bytes(2, 'big')

# Test case:
# data = b'\x01\x04\x00\x00\x00\x08'
# crc = calculate_crc(data)
# print(crc.hex())  # Output: 'abcd'


## Command for reading the measurement result
# // Construct ModbusRTU request packet:
# //
# // Byte | Description | Value (in hex)
# // --------------------------------------------------------------
# // 1 | Slave Address | 0x01
# // 2 | Function Code | 0x04
# // 3 | Register Address (High Byte) | 0x00
# // 4 | Register Address (Low Byte) | 0x10
# // 5 | Number of Registers (High Byte) | 0x00 0x00
# // 6 | Number of Registers (Low Byte) | 0x00 0x01
# // 7 | CRC Check (High Byte) | 0xAB
# // 8 | CRC Check (Low Byte) | 0xCD


### Example that reads 8 registers starting from address 0x00
# LENGTH_PKT = 8
# cmd = []
# cmd += [0x01, 0x04, 0x00, 0x00, 0x00, 0x08]
# cmd += [checksum(cmd)]

# # print(len(cmd))
# # print([hex(x) for x in cmd])


# ser = serial.Serial("/dev/ttyUSB1", BAUD_RATE, parity = PARITY,
#         stopbits= STOP_BIT, bytesize=BYTE_SIZE)
# print(ser.is_open)

# ser.write(cmd)

# print([hex(x) for x in cmd])

# response = ser.read(LENGTH_PKT)
# print(response)
# print(ser.is_open)

