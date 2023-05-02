## This program acts as a gateway on RaspberryPi for MEGNA POWER GENERATOR
## It writes serial data to request the current voltage
## and read the serial response getting the current voltage
## https://magna-power.com/assets/files/manuals/manual_ts_1.0.pdf

import socket

MODE_MAP = {"rotary": 0, "keypad": 1, "ext_pgm": 2, "remote": 3}


class hil_serial:
    def __init__(self, ip="192.168.0.98", port=50505):
        self.conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.conn.connect((ip, port))

    def __del__(self):
        self.ser.close()

    def set_mode(self, mode="remote"):
        self.sendall(b'CONF SETUP %d\n' % MODE_MAP[mode])

    def set_voltage_trigger(self, volt="MAX"):
        self.sendall(b'VOLT:TRIG %s\n' % str(volt))

    def set_current_trigger(self, curr="MAX"):
        self.sendall(b'CURR:TRIG %s\n' % str(curr))

    def set_voltage(self, volt):
        self.sendall(b'VOLT %f\n' % volt)

    def set_current(self, curr):
        self.sendall(b'CURR %f\n' % curr)
    
    def start(self):
        self.sendall(b'OUTP:START\n')
    
    def stop(self):
        self.sendall(b'OUTP:STOP\n')

    def get_voltage(self):
        self.sendall(b'MEAS:VOLT?\n')
        resp = float(self.conn.recv(4096).decode().strip())
        return resp

    def get_current(self):
        self.sendall(b'MEAS:CURR?\n')
        resp = float(self.conn.recv(4096).decode().strip())
        return resp
