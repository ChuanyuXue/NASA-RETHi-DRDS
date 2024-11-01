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
from hil_vxi11 import *

from subprocess import Popen
import time

ROBOT_ARM_ENABLE = False


class Agent:

    def __init__(self, local_ip=None, remote_ip=None):
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
            "PV_1_Voltage": 10019,
            "PV_1_Current": 10020,
            "PV_1_Power": 10021,
            "PV_2_Voltage": 10022,
            "PV_2_Current": 10023,
            "PV_2_Power": 10024,
            "PV_3_Voltage": 10025,
            "PV_3_Current": 10026,
            "PV_3_Power": 10027,
            "PV_4_Voltage": 10028,
            "PV_4_Current": 10029,
            "PV_4_Power": 10030,
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
        self.Power_meter = hil_vxi11("192.168.10.120")
                                
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
                send(self.udp_sock, self.remote_ip,
                     self.local_ports["PV_Current"], [curr])
                send(self.udp_sock, self.remote_ip,
                     self.local_ports["PV_Voltage"], [volt])
                print("PV_simulator --> Voltage: %f, Current: %f" %
                      (volt, curr))
                # volt = self.Amplifier.get_voltage()
                # curr = self.Amplifier.get_current()
                # print("Amplifier --> Voltage: %f, Current: %f"%(volt, curr))
                volt = self.Load_1.get_voltage()
                curr = self.Load_1.get_current()
                send(self.udp_sock, self.remote_ip,
                     self.local_ports["L1_Current"], [curr])
                send(self.udp_sock, self.remote_ip,
                     self.local_ports["L1_Voltage"], [volt])
                print("Load_1 --> Voltage: %f, Current: %f" % (volt, curr))
                
                ## Get the data from the solar panel
                for PV_chanel in [1,2,3,4]:
                    volt = self.Power_meter.get_voltage(PV_chanel)
                    curr = self.Power_meter.get_current(PV_chanel)
                    power = self.Power_meter.get_power(PV_chanel)
                    send(self.udp_sock, self.remote_ip,
                        self.local_ports[f"PV_{PV_chanel}_Voltage"], [volt])
                    send(self.udp_sock, self.remote_ip,
                            self.local_ports[f"PV_{PV_chanel}_Current"], [curr])
                    send(self.udp_sock, self.remote_ip,
                            self.local_ports[f"PV_{PV_chanel}_Power"], [power])
                    print(f"PV_{PV_chanel} --> Voltage: {volt}, Current: {curr}, Power: {power}")
                

                ## Get the command from OpalRT
                for data_name, sock in self.OpalRT_udp.items():
                    data = sock.receive_latest()
                    if data_name == "L1_Current_Set" and data != None:
                        print("Set-point", round(data[0], 2))
                        self.Load_1.set_current(round(data[0], 2))
                time.sleep(0.5)

            except KeyboardInterrupt:
                break

        self.PV_simulator.stop()
        self.Amplifier.stop()
        self.Load_1.stop()

    def str_agent(self):
        self.Temp_Sensor = hil_gpio()
        self.Press_Sensor_Recv = hil_adc('/dev/ttyACM0')
        self.Press_Sensor_Send = hil_adc('/dev/ttyACM1')
        self.Press_Sensor_Send.allOutput()

        for data_name in self.OpalRT_udp:
            self.OpalRT_udp[data_name].start()
        while True:
            try:
                temp = self.Temp_Sensor.read_temp()
                send(self.udp_sock, self.remote_ip, self.local_ports["Temp_1"],
                     [temp])
                print("Temp_1 --> Temperature: %f" % (temp))

                pres = self.Press_Sensor_Recv.readAnalog()
                send(self.udp_sock, self.remote_ip,
                     self.local_ports["Pressure_1"], [pres * 0.7])
                print("Pressure_1 --> Pressure: %f" % (pres * 0.7))
                if pres < 1.3 and ROBOT_ARM_ENABLE:
                    subprocess.Popen([
                        "python3", "utils/agent/lagacy/robot.py",
                        "192.168.10.180"
                    ])

                ## Get the command from OpalRT
                for data_name, sock in self.OpalRT_udp.items():
                    data = sock.receive_latest()
                    if data_name == "Swith_Compre" and data != None:
                        if data[0] == 0:
                            self.Press_Sensor_Send.clearPin(7)
                        elif data[0] == 1:
                            self.Press_Sensor_Send.setPin(7)
                        else:
                            print("Wrong command")

                        print("Set-point Compress", round(data[0], 2))
                    elif data_name == "Swith_Heatpad" and data != None:
                        if data[0] == 0:
                            self.Press_Sensor_Send.clearPin(6)
                        elif data[0] == 1:
                            self.Press_Sensor_Send.setPin(6)
                        else:
                            print("Wrong command")
                        print("Set-point Headpad", round(data[0], 2))
                    elif data != None:
                        print("Other Command ->", data_name, data[0])
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
