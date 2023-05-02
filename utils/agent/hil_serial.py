## This program acts as a gateway on RaspberryPi for MEGNA POWER GENERATOR
## It writes serial data to request the current voltage
## and read the serial response getting the current voltage
## https://magna-power.com/assets/files/manuals/manual_ts_1.0.pdf

import serial

MODE_MAP = {"rotary": 0, "keypad": 1, "ext_pgm": 2, "remote": 3}


class hil_serial:

    def __init__(self, device="/dev/ttyUSB0"):
        self.ser = serial.Serial(device,
                                 19200,
                                 parity=serial.PARITY_NONE,
                                 stopbits=serial.STOPBITS_ONE,
                                 bytesize=serial.EIGHTBITS)

    def __del__(self):
        self.ser.close()

    def set_mode(self, mode="remote"):
        self.ser.write(b'CONF SETUP %d\n' % MODE_MAP[mode])

    def set_voltage_trigger(self, volt="MAX"):
        self.ser.write(b'VOLT:TRIG %s\n' % str(volt))

    def set_current_trigger(self, curr="MAX"):
        self.ser.write(b'CURR:TRIG %s\n' % str(curr))

    def set_voltage(self, volt):
        self.ser.write(b'VOLT %f\n' % volt)

    def set_current(self, curr):
        self.ser.write(b'CURR %f\n' % curr)
    
    def start(self):
        self.ser.write(b'OUTP:START\n')
    
    def stop(self):
        self.ser.write(b'OUTP:STOP\n')

    def get_voltage(self):
        self.ser.write(b'MEAS:VOLT?\n')
        resp = self.ser.readline().decode()
        return eval(resp.replace('\n', ''))

    def get_current(self):
        self.ser.write(b'MEAS:CURR?\n')
        resp = self.ser.readline().decode()
        return eval(resp.replace('\n', ''))
