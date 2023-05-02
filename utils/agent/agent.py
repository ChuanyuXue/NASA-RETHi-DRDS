'''
The on board agent running on RaspberryPi 4B
- Collects the data from the multiple sensors
- Sends the command to the actuator
- Act as a gateway for the communication

This agent has no real-time ability
'''
from agent.hil_serial import hil_serial
import time


class Agent:

    def __init__(self, local_ip, remote_ip):
        self.local_ip = local_ip
        self.local_ports = {}

        self.remote_ip = remote_ip
        self.remote_ports = {}

        self.PV_simulator_conn = hil_serial()

    def run(self):
        self.PV_simulator_conn.set_voltage_trigger("MAX")
        self.PV_simulator_conn.set_current_trigger("MAX")
        self.PV_simulator_conn.set_voltage(10)
        self.PV_simulator_conn.set_current(1)
        self.PV_simulator_conn.start()
        time.sleep(10)
        self.PV_simulator_conn.stop()
