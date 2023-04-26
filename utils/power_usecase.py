'''
The on board agent running on RaspberryPi 4B
- Collects the data from the multiple sensors
- Sends the command to the actuator
- Act as a gateway for the communication

This agent has no real-time ability
'''

class Agent:
    def __init__(self, local_ip, remote_ip):
        self.local_ip = local_ip
        self.local_ports = {}

        self.remote_ip = remote_ip
        self.remote_ports = {}

        self.API = None
    
    def 
        