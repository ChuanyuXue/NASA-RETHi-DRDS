"""
Author: Chuanyu (skewcy@gmail.com)
hil_vxi11.py (c) 2023
Desc: description
Created:  2023-10-13T18:04:28.335Z
"""

import vxi11

class hil_vxi11:
    def __init__(self, ip, timeout=20000):
        self.vxi11 = vxi11.Instrument("TCPIP::{}::INSTR".format(ip))
        self.vxi11.timeout = timeout
    
    def get_voltage(self, pv_id=1):
        reg = (pv_id - 1) * 10 + 1
        return self.read("NUMERIC:NORMAL:VALUE? {}".format(reg))
    
    def get_current(self, pv_id=1):
        reg = (pv_id - 1) * 10 + 2
        return self.read("NUMERIC:NORMAL:VALUE? {}".format(reg))
    
    def get_power(self, pv_id=1):
        reg = (pv_id - 1) * 10 + 3
        return self.read("NUMERIC:NORMAL:VALUE? {}".format(reg))
    
    def read(self, comm):
        response = self.vxi11.ask(comm)
        return eval(response)
    

if __name__ == "__main__":
    hil = hil_vxi11("192.168.10.120")
    print(hil.get_voltage(1))
    print(hil.get_voltage(2))
    print(hil.get_voltage(3))
    

