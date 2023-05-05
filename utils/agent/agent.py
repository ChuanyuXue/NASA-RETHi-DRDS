'''
The on board agent running on RaspberryPi 4B
- Collects the data from the multiple sensors
- Sends the command to the actuator
- Act as a gateway for the communication

This agent has no real-time ability
'''

from hil_serial import *
from hil_tcp import *
from hil_udp import hil_udp, send
import time



class Agent:

    def __init__(self, local_ip = None, remote_ip = None):
        self.local_ip = "0.0.0.0"
        self.local_ports = {
            "L1_Votage": 10001,
            "L1_Current": 10002,
            "Swith_Compre": 10003,
            "Swith_Heatpad": 10004,
        }

        self.remote_ip = remote_ip
        self.remote_ports = {}

        self.PV_simulator = hil_serial("/dev/ttyUSB0")
        self.Amplifier = hil_serial("/dev/ttyUSB1")
        self.Load_1 = hil_tcp("192.168.10.98", port=50505)

        self.udp_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

        self.OpalRT_udp = {
            data_name: hil_udp(self.local_ip, self.local_ports[data_name])
            for data_name in self.local_ports 
        }

    def __del__(self):
        self.PV_simulator.stop()
        self.Amplifier.stop()
        self.Load_1.stop()
        for data_name in self.OpalRT_udp:
            self.OpalRT_udp[data_name].stop()
        self.udp_sock.close()

    def run(self):

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
                send(self.udp_sock, self.remote_ip, 10013, [curr])
                send(self.udp_sock, self.remote_ip, 10014, [volt])
                print("PV_simulator --> Voltage: %f, Current: %f"%(volt, curr))
                # volt = self.Amplifier.get_voltage()
                # curr = self.Amplifier.get_current()
                # print("Amplifier --> Voltage: %f, Current: %f"%(volt, curr))
                volt = self.Load_1.get_voltage()
                curr = self.Load_1.get_current()
                send(self.udp_sock, self.remote_ip, 10005, [curr])
                send(self.udp_sock, self.remote_ip, 10006, [volt])
                print("Load_1 --> Voltage: %f, Current: %f"%(volt, curr))

                ## Get the command from OpalRT
                for data_name, sock in self.OpalRT_udp.items():
                    data = sock.receive_latest()
                    if data_name == "L1_Current" and data != None:
                        self.Load_1.set_current(round(data[0], 2))
                time.sleep(0.5)

            except KeyboardInterrupt:
                break

        self.PV_simulator.stop()
        self.Amplifier.stop()
        self.Load_1.stop()

if __name__ == '__main__':
    agent = Agent(remote_ip="192.168.10.101")
    agent.run()
    # for i in range(5, 16):
    #     hil_udp.send(sock, "192.168.10.101", 10000 + i,  [i])

