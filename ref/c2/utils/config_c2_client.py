# Command and Control (C2) Client Configurations

# Client Operational Configs
c2_client_ip = "192.168.1.116"
c2_client_ip = "127.0.0.1"
c2_client_port = 10000
c2_client_time_schedule = 60 # sec
test_bed_frequency = 1000 # Hz


# Database configurations
data_base_folder = r'./HMS/'
data_base_location = data_base_folder + \
    r'/database/mcvt_run_agnt_spg_ep_ed_new.db'

c2_client_table_config = [
		{
			"table_id": 1,
			"table_name": "FDD_SPG_DUST",
			"nH": 4,
			"type": "sim_fdd",
			"mode": "read",
		},
		{
			"table_id": 2,
			"table_name": "FDD_ECLSS_DUST",
			"nH": 50,
			"type": "sim_fdd",
			"mode": "read",
		},
		{
			"table_id": 3,
			"table_name": "FDD_ECLSS_PAINT",
			"nH": 50,
			"type": "sim_fdd",
			"mode": "read",
		},
		{
			"table_id": 4,
			"table_name": "FDD_STR_DMG",
			"nH": 1,
			"type":"sim_fdd",
			"mode": "read",
		},
		{
			"table_id": 5,
			"table_name": "FDD_NPG_DUST",
			"nH": None,
			"type":  "npg",
			"mode": "read",
		},
		{
			"table_id": 6,
			"table_name": "STATES_AGENT",
			"nH": None,
			"type": "agent",
			"mode": "read",
		}
	]

# Decision Making Configurations

solar_pv_fault_category  = 3
solar_pv_fault_threshold = 0.7

eclss_dust_fault_threshold = 15
eclss_paint_fault_threshold = 15

structure_damage_threshold = 0.7

nuclear_fault_threshold = 1
