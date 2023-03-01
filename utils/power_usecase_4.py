## This code is for the PZEM-003/017 DC communication module

import serial
import time
import datetime
from modbus_tk import modbus_rtu
import modbus_tk


## Communication configurations
BAUD_RATE = 9600
PORT = "/dev/ttyUSB1"
BYTE_SIZE = serial.EIGHTBITS
STOP_BIT = serial.STOPBITS_TWO
PARITY = serial.PARITY_NONE

# def calculate_crc(data):
#     # The ModbusRTU CRC is a 16-bit value calculated over the entire packet,
#     # excluding the CRC itself. The polynomial used is x^16 + x^15 + x^2 + 1.
#     # This function implements the CRC calculation algorithm.
    
#     crc = 0xFFFF
#     for byte in data:
#         crc ^= byte
#         for _ in range(8):
#             if crc & 0x0001:
#                 crc >>= 1
#                 crc ^= 0xA001
#             else:
#                 crc >>= 1
#     return [(crc >> 8) & 0xFF, crc & 0xFF]

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
SLAVE_ADDR = 1
HOLDING_REG_ADDR = 0x0000
LENGTH_PKT = 8
TIMEOUT = 5


# cmd = []
# cmd += [0x01, 0x04, 0x00, 0x00, 0x00, 0x02]
# cmd += calculate_crc(cmd)

# ser = serial.Serial("/dev/ttyUSB1", BAUD_RATE, parity = PARITY,
#         stopbits= STOP_BIT, bytesize=BYTE_SIZE, timeout=5)
# print(ser.is_open)

# ser.write(cmd)
# print([hex(x) for x in cmd])
# time.sleep(1)
# response = ser.read()
# print(response)
# print(ser.is_open)
try:
    ser = serial.Serial(port=PORT, baudrate=BAUD_RATE, bytesize=BYTE_SIZE, parity=PARITY, stopbits=STOP_BIT, timeout=TIMEOUT, xonxoff=0)

    # Create a Modbus master object using the serial port
    master = modbus_rtu.RtuMaster(ser)

    # Set the Modbus communication parameters
    master.set_timeout(TIMEOUT)
    # master.set_byteorder(modbus_rtu.BIG_ENDIAN)

    # Read the holding register value
    response = master.execute(SLAVE_ADDR, modbus_tk.defines.READ_INPUT_REGISTERS, HOLDING_REG_ADDR, 8)
    print(response)
except modbus_tk.modbus.ModbusError as e:
    print("%s- Code=%d" % (e, e.get_exception_code()))

