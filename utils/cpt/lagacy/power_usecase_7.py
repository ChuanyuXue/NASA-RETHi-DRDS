"""
Author: Chuanyu (skewcy@gmail.com)
power_usecase_7.py (c) 2023
Desc: description
Created:  2023-10-07T18:35:32.156Z
"""

from pymodbus.client import ModbusTcpClient

client = ModbusTcpClient('192.168.10.120', port=10001)
client.connect()
result = client.read_holding_registers(0, 70)
data = result.registers
print(data)
client.close()

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