# Database Server Configurations
data_base_location = r'./HMS/database/mcvt_run_agnt_spg_ep_ed_new.db'

database_server_ip = "127.0.0.1"
database_server_port = 10011
database_server_buf_size = 1024

database_table_config = [
        {
            "table_id": 1,
            "table_name": "FDD_SPG_DUST",
            "nH": 4,
            "type": "sim_fdd",
            "mode": "write",
        },
        {
            "table_id": 2,
            "table_name": "FDD_ECLSS_DUST",
            "nH": 50,
            "type": "sim_fdd",
            "mode": "write",
        },
        {
            "table_id": 3,
            "table_name": "FDD_ECLSS_PAINT",
            "nH": 50,
            "type": "sim_fdd",
            "mode": "write",
        },
        {
            "table_id": 4,
            "table_name": "FDD_STR_DMG",
            "nH": 1,
            "type": "sim_fdd",
            "mode": "write",
        },
        {
            "table_id": 5,
            "table_name": "FDD_NPG_DUST",
            "nH": None,
            "type": "npg",
            "mode": "write",
        },
        {
            "table_id": 6,
            "table_name": "STATES_AGENT",
            "nH": None,
            "type": "agent",
            "mode": "write",
        }
    ]

# Command and Control (C2) Client Configurations
