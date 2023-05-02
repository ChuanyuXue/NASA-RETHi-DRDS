## This program acts as a gateway on RaspberryPi for MEGNA POWER GENERATOR
## It writes serial data to request the current voltage
## and read the serial response getting the current voltage
## https://magna-power.com/assets/files/manuals/manual_ts_1.0.pdf

import socket
import time

MODE_MAP = {"rotary": 0, "keypad": 1, "ext_pgm": 2, "remote": 3}


class hil_tcp:
    def __init__(self, ip="192.168.0.98", port=50505):
        self.conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.conn.connect((ip, port))

    def __del__(self):
        self.conn.close()

    def set_mode(self, mode="remote"):
        self.conn.sendall(b'CONF SETUP %d\n' % MODE_MAP[mode])
        time.sleep(0.1)

    def set_voltage_trigger(self, volt="MAX"):
        self.conn.sendall(b'VOLT:TRIG %s\n' % str(volt).encode())
        time.sleep(0.1)

    def set_current_trigger(self, curr="MAX"):
        self.conn.sendall(b'CURR:TRIG %s\n' % str(curr).encode())
        time.sleep(0.1)

    def set_voltage(self, volt):
        self.conn.sendall(b'VOLT %s\n' % str(volt).encode())
        time.sleep(0.1)

    def set_current(self, curr):
        self.conn.sendall(b'CURR %s\n' %str(curr).encode())
        time.sleep(0.1)
    
    def start(self):
        self.conn.sendall(b'OUTP:START\n')
        time.sleep(0.1)
    
    def stop(self):
        self.conn.sendall(b'OUTP:STOP\n')
        time.sleep(0.1)

    def get_voltage(self):
        self.conn.sendall(b'MEAS:VOLT?\n')
        time.sleep(0.1)
        resp = float(self.conn.recv(4096).decode().strip())
        return resp

    def get_current(self):
        self.conn.sendall(b'MEAS:CURR?\n')
        time.sleep(0.1)
        resp = float(self.conn.recv(4096).decode().strip())
        return resp
