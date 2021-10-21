
import socket
import time
import numpy as np
from utils.packet import Packet
from utils.tableHandler import SimFDDTableHandler, AgentTableHandler, NPGTableHandler
from policy.reflexivePolicy import SolarPVPolicy, ECLSSPolicy, StructurePolicy, NPGPolicy
import utils.config_c2_client as cfg
from utils.tunnel import Tunnel


class Client:

    def __init__(self, ip, port, config, dbLoc=None):
        assert isinstance(config, list), "Configuration should be a list!"
        assert dbLoc is not None, "Please give valid DB location!"
        self.config_list = config
        self.dbLoc = dbLoc
        self.ip = ip
        self.port = port
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.valid_handler_types = ["sim_fdd", "agent", "npg"]

        #self.tunnel = Tunnel("localhost", 60002)

    def create_table_handlers(self):
        ''' Create table handlers for the C2 Client
        '''
        self.tableHandlers = []
        self.l_ts = {}
        for i, config in enumerate(self.config_list):
            _type = config["type"]
            assert _type in self.valid_handler_types, "[!] Not a valid handler type!!"
            handle = {}
            handle["name"] = config["table_name"]
            handle["mode"] = config["mode"]
            name = config["table_name"]
            mode = config["mode"]
            # handle = {}
            if _type == "sim_fdd":
                nH = config["nH"]
                # handle["name"] = name
                # handle["mode"] = mode
                handle["l_ts"] = None
                handle["handler"] = SimFDDTableHandler(
                    name, nH, mode, self.dbLoc)
                # self.tableHandlers[name] =
                # self.l_ts[name] = None
            elif _type == "agent":
                handle["l_ts"] = None
                handle["handler"] = AgentTableHandler(name, mode, self.dbLoc)
            elif _type == "npg":
                handle["l_ts"] = None
                handle["handler"] = NPGTableHandler(name, mode, self.dbLoc)
            self.tableHandlers.append(handle)

    def get_data(self):
        ''' Fetch data from the 'read' table handlers
        '''
        data = {}
        nData = {}
        assert self.tableHandlers is not False, "[!] Can't fetch data from empty table-handlers!"
        for handler in self.tableHandlers:
            if handler["mode"] == "read":
                data[handler["name"]], handler["l_ts"] = handler["handler"].fetch_from_table(
                    handler["l_ts"], debug=False)
                nData[handler["name"]] = np.asarray(
                    data[handler["name"]], dtype=np.float64)
            else:  # Ignore any other mode
                pass
        return data, nData

    def start_client(self, fs_testbed, dm_cfg, CYCLE_TIME=60):
        '''Start performing Decision Making
        '''
        self.create_table_handlers()

        rp_spgDust = SolarPVPolicy(category=dm_cfg["spg_dust"][0],
                                   threshold=dm_cfg["spg_dust"][1])
        rp_eclssDust = ECLSSPolicy(fault_name='dust',
                                   threshold=dm_cfg["eclss_dust"])
        rp_eclssPaint = ECLSSPolicy(fault_name='paint',
                                    threshold=dm_cfg["eclss_paint"])
        rp_strDmg = StructurePolicy(threshold=dm_cfg["structure"])
        rp_npgDust = NPGPolicy(threshold=dm_cfg["npg_dust"])
        toSend = []
        toSend_history = []
        cnt = 1
        while True:
            data, nData = self.get_data()
            nData_spgDust = nData["FDD_SPG_DUST"]
            nData_eclssDust = nData["FDD_ECLSS_DUST"]
            nData_eclssPaint = nData["FDD_ECLSS_PAINT"]
            nData_strDmg = nData["FDD_STR_DMG"]
            nData_npgDust = nData["FDD_NPG_DUST"]
            nData_agnt = nData["STATES_AGENT"]

            # Sending back!!
            uniqueActs = np.unique(nData_agnt[:, 1:])
            lastAgentAct = nData_agnt[-1, 1]
            last_ts = nData_agnt[-1, 0]
            msg = ("""
				======================================================
				Until {:0.4f}s of testbed time
				======================================================
				""".format(last_ts/fs_testbed))
            print(msg)
            log = {
                "type": 0,
                "msg": msg
            }

            act_spgDust, eHS_spgDust = rp_spgDust.act_mod(
                nData_spgDust[:, 1:], nData_agnt[:, 1:])
            act_eclssDust, eHS_eclssDust = rp_eclssDust.act_mod(
                nData_eclssDust[:, 1:], nData_agnt[:, 1:])
            act_eclssPaint, eHS_eclssPaint = rp_eclssPaint.act_mod(
                nData_eclssPaint[:, 1:], nData_agnt[:, 1:])
            act_strDmg, eHS_strDmg = rp_strDmg.act(
                nData_strDmg[:, 1:], nData_agnt[:, 1:])
            act_npgDust, eHS_npgDust = rp_npgDust.act(
                nData_npgDust[:, 1:], nData_agnt[:, 1:])
            # _, _ = rp_eclssDust.act_mod(nData_eclssDust[:,1:], nData_agnt[:,1:])
            # _, _ = rp_eclssPaint.act_mod(nData_eclssPaint[:,1:], nData_agnt[:,1:])
            # _, _ = rp_spgDust.act_mod(nData_spgDust[:,1:], nData_agnt[:,1:])
            # act_spgDust = -1.0
            # act_eclssDust = -1.0
            # act_eclssPaint = -1.0
            # act_strDmg = -1.0
            # act_npgDust = -1.0
            # List of expected health states
            exp_hs = [eHS_spgDust, eHS_eclssDust,
                      eHS_eclssPaint, eHS_strDmg, eHS_npgDust]
            # List of suggested actions
            suggested_acts = [act_spgDust, act_eclssDust,
                              act_eclssPaint, act_strDmg, act_npgDust]

            for act in suggested_acts:
                if act != -1.0 and act not in toSend:
                    toSend.append(act)
                    toSend_history.append(act)
                else:
                    pass

            if lastAgentAct == -1.0:
                if not toSend:
                    comms_to_simulink = -1.0
                else:
                    comms_to_simulink = toSend.pop(0)
            else:
                comms_to_simulink = -1.0

            pkt = Packet()
            buf = pkt.pkt2Buf(
                _src=0,
                _dst=2,
                _type=3,
                _priority=7,
                _row=1,
                _col=1,
                _length=1,
                _payload=[comms_to_simulink])
            self.socket.sendto(buf, (self.ip, self.port))
            cnt += 1
            # toSend, toSend_Hist, uniqueActs, commSimulink
            self.client_display(toSend=toSend,
                                toSend_Hist=toSend_history,
                                uniqueActs=uniqueActs,
                                commSimulink=comms_to_simulink)

            estimation_dict = {
                "exp_hs": exp_hs,
                "acts": suggested_acts
            }
            action_dict = {
                "to_send": toSend,
                "to_send_hist": toSend_history,
                "unique_acts": uniqueActs,
                "simulink_comms": comms_to_simulink
            }
            self.send_to_tunnel(estimation_dict, action_dict)

            time.sleep(CYCLE_TIME)

    def client_display(self, toSend, toSend_Hist, uniqueActs, commSimulink):
        ''' Display method for the client
        '''
        print_map = {
            6: "Idle",
            1: "Repair Solar-PV [Dust]",
            2: "Repair ECLSS Panels [Dust]",
            3: "Repair ECLSS Panels [Paint]",
            4: "Repair Sructure Damage",
            5: "Repair Nuclear-PG [Dust]"
        }
        i_toSend = [int(i) for i in toSend]
        i_toSend_Hist = [int(i) for i in toSend_Hist]
        i_uniqueActs = [int(i) for i in uniqueActs]
        i_commSimulink = int(commSimulink)

        c_toSend = [print_map[i] if i != -1 else print_map[6]
                    for i in i_toSend]
        c_toSend_Hist = [print_map[i] if i != -1 else print_map[6]
                         for i in i_toSend_Hist]
        c_uniqueActs = [print_map[i] if i != -1 else print_map[6]
                        for i in i_uniqueActs]
        c_commSimulink = print_map[i_commSimulink] if i_commSimulink != - \
            1 else print_map[6]

        # print(f"Command to Simulink: {c_commSimulink}")
        # print(f"Agent data: {','.join(c_uniqueActs)}")
        # print(f"Current `toSend` List: {','.join(c_toSend)}")
        # print(f"Valid Command history: {','.join(c_toSend_Hist)}")

        msg = f"Command to Simulink: {c_commSimulink}\n"
        msg += f"Agent data: {','.join(c_uniqueActs)}\n"
        msg += f"Current `toSend` List: {','.join(c_toSend)}\n"
        msg += f"Valid Command history: {','.join(c_toSend_Hist)}\n"
        print(msg)
        # log = {
        #     "type": 0,
        #     "msg": msg
        # }
        # self.tunnel.send(log)

    def send_to_tunnel(self, estimation_dict, action_dict):
        ''' Formats the `Estimation` and `Action` dictionaries of the C2
        for display in the console of the web app
        '''
        print_map = {
            6: "Idle",
            1: "Repair Solar-PV [Dust]",
            2: "Repair ECLSS Panels [Dust]",
            3: "Repair ECLSS Panels [Paint]",
            4: "Repair Sructure Damage",
            5: "Repair Nuclear-PG [Dust]"
        }
        # Estimation Dicts
        spg_dict = {
            "name": "Solar-PV [Dust]",
            "hs": estimation_dict["exp_hs"][0],
            "sugg_act": estimation_dict["acts"][0]
        }
        eclss_dust_dict = {
            "name": "ECLSS Panels [Dust]",
            "hs": estimation_dict["exp_hs"][1],
            "sugg_act": estimation_dict["acts"][1]
        }
        eclss_paint_dict = {
            "name": "ECLSS Panels [Paint]",
            "hs": estimation_dict["exp_hs"][2],
            "sugg_act": estimation_dict["acts"][2]
        }
        str_dict = {
            "name": "Structure Panel Damage",
            "hs": estimation_dict["exp_hs"][3],
            "sugg_act": estimation_dict["acts"][3]
        }
        npg_dict = {
            "name": "Nuclear Radiator [Dust]",
            "hs": float(estimation_dict["exp_hs"][4]), # !numpy type to json error
            "sugg_act": estimation_dict["acts"][4]
        }

        est = [spg_dict, eclss_dust_dict, eclss_paint_dict, str_dict, npg_dict]
        # Tunnel about Actions
        act = {
            "current_action": action_dict["unique_acts"].tolist(), # !numpy type to json error
            "sent_to_simulink": action_dict["simulink_comms"]
        }
        # act = {
        #     "current_action": action_dict["unique_acts"].tolist(), # !numpy type to json error
        #     "sent_to_simulink": action_dict["unique_acts"].tolist()[-1]
        # }

        log = {
            "type": 1,
            "stats_c2": {
                "estimation": est,
                "action": act
            }
        }
        # print(log)
        self.tunnel.send(log)


if __name__ == "__main__":

    CL_IP = cfg.c2_client_ip
    CL_PORT = cfg.c2_client_port
    CYCLE_TIME = cfg.c2_client_time_schedule
    fs_testbed = cfg.test_bed_frequency
    dbLoc = cfg.data_base_location

    dm_config = {
        "spg_dust": [cfg.solar_pv_fault_category, cfg.solar_pv_fault_threshold],
        "eclss_dust": cfg.eclss_dust_fault_threshold,
        "eclss_paint": cfg.eclss_paint_fault_threshold,
        "structure": cfg.structure_damage_threshold,
        "npg_dust": cfg.nuclear_fault_threshold

    }
    tblConfig = cfg.c2_client_table_config
    C2Client = Client(CL_IP, CL_PORT, tblConfig, dbLoc)
    C2Client.start_client(fs_testbed, dm_config, CYCLE_TIME)
