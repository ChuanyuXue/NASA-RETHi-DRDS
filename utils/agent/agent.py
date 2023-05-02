'''
The on board agent running on RaspberryPi 4B
- Collects the data from the multiple sensors
- Sends the command to the actuator
- Act as a gateway for the communication

This agent has no real-time ability
'''

from hil_serial import *
from hil_tcp import *
import time


class Agent:

    def __init__(self, local_ip = None, remote_ip = None):
        self.local_ip = local_ip
        self.local_ports = {}

        self.remote_ip = remote_ip
        self.remote_ports = {}

        self.PV_simulator = hil_serial("/dev/ttyUSB0")
        self.Amplifier = hil_serial("/dev/ttyUSB1")
        self.Load_1 = hil_tcp("192.168.10.98", port=50505)

    def run(self):
        # self.PV_simulator.set_voltage_trigger("MAX")
        # self.PV_simulator.set_current_trigger("MAX")
        # self.PV_simulator.set_voltage(10)
        # self.PV_simulator.set_current(1)

        # self.Amplifier.set_voltage_trigger("MAX")
        # self.Amplifier.set_current_trigger("MAX")
        # self.Amplifier.set_voltage(10)
        # self.Amplifier.set_current(1)

        # self.Load_1.set_voltage(10) 
        # self.Load_1.set_current(1)

        self.Amplifier.start()
        self.PV_simulator.start()
        time.sleep(10)
        self.Load_1.start()

        while True:
            try:
                volt = self.PV_simulator.get_voltage()
                curr = self.PV_simulator.get_current()
                print("PV_simulator --> Voltage: %f, Current: %f"%(volt, curr))
                volt = self.Amplifier.get_voltage()
                curr = self.Amplifier.get_current()
                print("Amplifier --> Voltage: %f, Current: %f"%(volt, curr))
                volt = self.Load_1.get_voltage()
                curr = self.Load_1.get_current()
                print("Load_1 --> Voltage: %f, Current: %f"%(volt, curr))
                time.sleep(1)
            except KeyboardInterrupt:
                break

        self.PV_simulator.stop()
        self.Amplifier.stop()
        self.Load_1.stop()


if __name__ == '__main__':
    agent = Agent()
    agent.run()