'''
The on board agent running on RaspberryPi 4B
- Collects the data from the multiple sensors
- Sends the command to the actuator
- Act as a gateway for the communication

This agent has no real-time ability
'''
import sys
from hil_serial import *
from hil_tcp import *
from hil_udp import hil_udp, send
from hil_adc import *
from hil_gpio import *

import time



class Agent:
    def __init__(self, local_ip = None, remote_ip = None):
        self.local_ip = "0.0.0.0"
        self.local_ports = {
            "L1_Current_set": 10001,
            "L1_Voltage_set": 10002,
            "Swith_Compre": 10003,
            "Swith_Heatpad": 10004,
            "L1_Current": 10005,
            "L1_Voltage": 10006,
            "PV_Current": 10013,
            "PV_Voltage": 10014,
            "Pressure_1": 10015,
            "Pressure_2": 10016,
            "Temp_1": 10017,
            "Temp_2": 10018,
        }

        self.remote_ip = remote_ip
        self.remote_ports = {}

        self.udp_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.OpalRT_udp = {
            data_name: hil_udp(self.local_ip, self.local_ports[data_name])
            for data_name in self.local_ports 
        }

    def __del__(self):
        if self.PV_simulator != None:
            self.PV_simulator.stop()
        if self.Amplifier != None:
            self.Amplifier.stop()
        if self.Load_1 != None:
            self.Load_1.stop()
        for data_name in self.OpalRT_udp:
            self.OpalRT_udp[data_name].stop()
        self.udp_sock.close()
    
    def power_agent(self):
        self.PV_simulator = hil_serial("/dev/ttyUSB0")
        self.Amplifier = hil_serial("/dev/ttyUSB1")
        self.Load_1 = hil_tcp("192.168.10.98", port=50505)
        #### Don't set trigger!!!!!!!
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
        time.sleep(5)
        self.Load_1.start()

        for data_name in self.OpalRT_udp:
            self.OpalRT_udp[data_name].start()

        while True:            
            try:
                ## Receive the data from sensors
                volt = self.PV_simulator.get_voltage()
                curr = self.PV_simulator.get_current()
                send(self.udp_sock, self.remote_ip, self.local_ports["PV_Current"], [curr])
                send(self.udp_sock, self.remote_ip, self.local_ports["PV_Voltage"], [volt])
                print("PV_simulator --> Voltage: %f, Current: %f"%(volt, curr))
                # volt = self.Amplifier.get_voltage()
                # curr = self.Amplifier.get_current()
                # print("Amplifier --> Voltage: %f, Current: %f"%(volt, curr))
                volt = self.Load_1.get_voltage()
                curr = self.Load_1.get_current()
                send(self.udp_sock, self.remote_ip, self.local_ports["L1_Current"], [curr])
                send(self.udp_sock, self.remote_ip, self.local_ports["L1_Voltage"], [volt])
                print("Load_1 --> Voltage: %f, Current: %f"%(volt, curr))

                _, pres = read_analog("192.168.10.99", 1)
                send(self.udp_sock, self.remote_ip, self.local_ports["Pressure_1"], [pres * 0.7])
                print("Pressure_1 --> Pressure: %f"%(pres * 0.7))

                ## Get the command from OpalRT
                for data_name, sock in self.OpalRT_udp.items():
                    data = sock.receive_latest()
                    if data_name == "L1_Current_Set" and data != None:
                        print("Set-point", round(data[0], 2))
                        self.Load_1.set_current(round(data[0], 2))
                    if data_name == "Swith_Compre" and data != None:
                        print("Set-point", round(data[0], 2))
                        write_analog("192.168.10.99", 0, int(data[0]))
                time.sleep(0.5)

            except KeyboardInterrupt:
                break

        self.PV_simulator.stop()
        self.Amplifier.stop()
        self.Load_1.stop()

    def str_agent(self):
        self.Temp_Sensor = hil_gpio()
        for data_name in self.OpalRT_udp:
            self.OpalRT_udp[data_name].start()
        while True:            
            try:
                temp = self.Temp_Sensor.read_temp()
                send(self.udp_sock, self.remote_ip, self.local_ports["Temp_1"], [temp])
                print("Temp_1 --> Temperature: %f"%(temp))
                ## Get the command from OpalRT
                for data_name, sock in self.OpalRT_udp.items():
                    data = sock.receive_latest()
                    pass
                time.sleep(0.5)

            except KeyboardInterrupt:
                break

    def run(self):
        if sys.argv[1] == "1":
            self.power_agent()
        elif sys.argv[1] == "2":
            self.str_agent()
        else:
            print("Invalid argument")

if __name__ == '__main__':
    
    # for i in range(5, 16):
    #     hil_udp.send(sock, "192.168.10.101", 10000 + i,  [i])
    agent = Agent(remote_ip="192.168.10.101")
    agent.run()
