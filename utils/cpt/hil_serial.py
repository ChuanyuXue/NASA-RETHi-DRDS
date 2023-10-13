## This program acts as a gateway on RaspberryPi for MEGNA POWER GENERATOR
## It writes serial data to request the current voltage
## and read the serial response getting the current voltage
## https://magna-power.com/assets/files/manuals/manual_ts_1.0.pdf

import serial
import time

MODE_MAP = {"rotary": 0, "keypad": 1, "ext_pgm": 2, "remote": 3}


class hil_serial:
    def __init__(self, device="/dev/ttyUSB0"):
        self.ser = serial.Serial(device,
                                 19200,
                                 parity=serial.PARITY_NONE,
                                 stopbits=serial.STOPBITS_ONE,
                                 bytesize=serial.EIGHTBITS)
        time.sleep(1)
        self.ser.write(b'CONF:SETPT 1\n')
        time.sleep(0.1)

    def set_mode(self, mode="remote"):
        self.ser.write(b'CONF SETUP %s\n' % str(MODE_MAP[mode]).encode())
        time.sleep(0.1)

    def set_voltage_trigger(self, volt="MAX"):
        self.ser.write(b'VOLT:TRIG %s\n'%str(volt).encode())
        time.sleep(0.1)

    def set_current_trigger(self, curr="MAX"):
        self.ser.write(b'CURR:TRIG %s\n'%str(curr).encode())
        time.sleep(0.1)

    def set_voltage(self, volt):
        self.ser.write(b'VOLT %s\n'%str(volt).encode())
        time.sleep(0.1)

    def set_current(self, curr):
        self.ser.write(b'CURR %s\n'%str(curr).encode())
        time.sleep(0.1)
    
    def start(self):
        self.ser.write(b'OUTP:START\n')
        time.sleep(0.1)
    
    def stop(self):
        self.ser.write(b'OUTP:STOP\n')
        time.sleep(0.1)

    def get_voltage(self):
        self.ser.write(b'MEAS:VOLT?\n')
        time.sleep(0.1)
        resp = self.ser.readline().decode()
        return eval(resp.replace('\n', ''))

    def get_current(self):
        self.ser.write(b'MEAS:CURR?\n')
        time.sleep(0.1)
        resp = self.ser.readline().decode()
        return eval(resp.replace('\n', ''))
