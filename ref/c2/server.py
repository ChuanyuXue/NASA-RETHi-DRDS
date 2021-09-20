''' Database Server for Command & Control (C2)
By- Murali Krishnan R
'''
import socket
import sqlite3
from sqlite3 import Error
from utils.packet import Packet
from utils.tableHandler import SimFDDTableHandler, AgentTableHandler, NPGTableHandler
import time
from utils.tunnel import Tunnel
import utils.config_db_server as config


class DatabaseServer:
    ''' Database server object
    '''

    def __init__(self, ip, port, config, dbLoc=None):
        assert isinstance(config, list), "configuration should be list!"
        assert dbLoc is not None, "Please give valid DB Location!"
        self.config_list = config
        self.dbLoc = dbLoc
        self.ip = ip
        self.port = port
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.valid_handler_types = ["sim_fdd", "agent", "npg"]

        # Jiachen: tunnel for redirecting outputs
        self.tunnel = Tunnel("localhost", 60001)

    def create_table_handlers(self):
        '''Create table handlers for the Database Server
        '''
        self.tableHandlers = {}
        for i, config in enumerate(self.config_list):
            _type = config["type"]
            assert _type in self.valid_handler_types, "[!] Not a valid handler type!!"
            tableID = config["table_id"]
            name = config["table_name"]
            mode = config["mode"]
            if _type == "sim_fdd":
                nH = config["nH"]
                self.tableHandlers[tableID] = SimFDDTableHandler(
                    name, nH, mode, self.dbLoc)
            elif _type == "agent":
                self.tableHandlers[tableID] = AgentTableHandler(
                    name, mode, self.dbLoc)
            elif _type == "npg":
                self.tableHandlers[tableID] = NPGTableHandler(
                    name, mode, self.dbLoc)

    def serve_database(self, buf_size):
        '''Start serving the database
        '''
        self.create_table_handlers()
        # print(self.tableHandlers)
        print("""
		##################################################################
		######### Command and Control (C2) Database Server ###############
		#########     Using SQLite Version: {0}            #############
		##################################################################
		""".format(sqlite3.version))
        self.socket.bind((self.ip, self.port))
        print(f"\033 Listening to {self.ip}:{self.port} ...")
        print("Currently listening for :")
        print([c["table_name"] for c in tblConfig])
        pktCnt = 0
        writeCnt = [0] * 6  # Hard-coded!!!
        while True:
            dataBuf, addr = self.socket.recvfrom(buf_size)
            pktCnt += 1
            pkt = Packet()
            if len(dataBuf) > 7:
                tableID, vals = pkt.get_values(dataBuf)
                try:
                    tbh = self.tableHandlers[tableID]
                    tbh.insert_into_table(vals)
                    writeCnt[tableID-1] += 1
                    # Jiachen: send log through tunnel
                    log = {
                        "type": 0,
                        "msg": f"Insert entry #{pktCnt} into [{tblConfig[tableID-1]['table_name']}]"
                    }
                    self.tunnel.send(log)

                    # send entries counter
                    if pktCnt%5==0:
                        log_stats = {
                            "type": 1,
                            "stats_dr": writeCnt
                        }
                        time.sleep(0.0001)
                        self.tunnel.send(log_stats)
                    
                except Error as e:
                    msg = f"Error inserting data: {e} {tableID} {vals}"
                    log = {
                        "type": 0,
                        "msg": msg
                    }
                    self.tunnel.send(log)
                    print("[!] "+msg)


if __name__ == "__main__":

    # Assign from config file
    dbLoc = config.data_base_location
    tblConfig = config.database_table_config
    SRV_IP = config.database_server_ip
    SRV_PORT = config.database_server_port
    buf_size = config.database_server_buf_size
    
    C2DBServer = DatabaseServer(SRV_IP, SRV_PORT, tblConfig, dbLoc)
    C2DBServer.serve_database(buf_size)
