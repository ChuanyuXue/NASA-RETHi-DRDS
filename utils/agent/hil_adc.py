# import subprocess


# def read_analog(ip, pin):
#     value = subprocess.run(["./eth32/eth32-example/recv", "192.168.10.99", str(pin)], capture_output=True)
#     ref, volt = value.stdout.decode().replace('\n','').split(',')
#     return (eval(ref), eval(volt))

# def write_analog(ip, pin, value):
#     return subprocess.call(
#         ["./eth32/eth32-example/comm",
#          str(ip), str(pin),
#          str(value)])

# if __name__ == '__main__':
#     # write_analog("192.168.10.99", 0, 1)
#     print(read_analog("192.168.10.99", 1))


#### Switch ETH-ADC to TOMOTO-ADC:

import serial
import time

class hil_adc:
    def __init__(self, device="/dev/ttyUSB0"):
        self.ser = serial.Serial(device, 19200, timeout=1)
        time.sleep(1)

    def allOutput(self,):
        self.ser.write("gpio iodir 00\r".encode())
    
    def setPin(self, pin):
        self.ser.write(f"gpio set {pin}\r".encode())

    def clearPin(self, pin):
        self.ser.write(f"gpio clear {pin}\r".encode())
    
    def readAnalog(self, pin = 5):
        self.ser.write(f"adc read {pin}\r".encode())
        response = self.ser.read(25).decode()
        voltage = eval(response.split('\n')[1]) / 1023 * 5.2
        return voltage

