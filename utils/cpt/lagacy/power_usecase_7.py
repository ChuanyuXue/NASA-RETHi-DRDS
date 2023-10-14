"""
Author: Chuanyu (skewcy@gmail.com)
power_usecase_7.py (c) 2023
Desc: description
Created:  2023-10-07T18:35:32.156Z
"""

import vxi11
import argparse


parser = argparse.ArgumentParser(description="Send a query to the instrument")
parser.add_argument('command', type=str, help="The query command to send")
args = parser.parse_args()

# Connect to the instrument
instr = vxi11.Instrument("TCPIP::192.168.10.120::INSTR")
instr.timeout = 20000  # Set timeout to 20 seconds

# Send the query and receive the response
# response = instr.ask(":INPUT:CURRent?")

# print("Response:", response)

# Send the query and receive the response
# response = instr.ask(":INPUT:VOLTage:AUTO?")


# response = instr.ask(":INPUT:SYNCHRONIZE:RECTIFIER:VOLTAGE:ELEMNE1?")

response = instr.ask(args.command)
print("Response:", response)

# Close the connection
instr.close()


##import logging
##from pymodbus.client import ModbusTcpClient
##
##logging.basicConfig()
##log = logging.getLogger()
##log.setLevel(logging.DEBUG)
##
##client = ModbusTcpClient('192.168.10.120', 502)
##
##if client.connect():
##    print("connected")
##    result = client.read_input_registers(101, 200)
##    print(type(result))
##else:
##    print("Failed to connect")
##
##client.close()


# from ftplib import FTP

# host = '192.168.10.120'
# port = 10001
# usr = 'anonymous'
# pwd = ''
# ftp = FTP()
# ftp.connect(host, port)
# ftp.login(usr, pwd)
# ftp.sendcmd("*IDN?")
# ftp.quit()