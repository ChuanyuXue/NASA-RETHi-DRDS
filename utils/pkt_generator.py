import pyapi.api as api
import time
import json
import random
import json
import random

DURATION = 10
SIMULATION_TIME = 4000

ins = api.API(
    local_ip="0.0.0.0",
    local_port=61234,
    remote_ip="localhost",
    # remote_port=10000 + 3,
    remote_port=10003,
    # remote_port=10000 + int(data['data_subtype1']),
    # remote_port=65533, # for local testing
    # remote_port=65531,  # for data service testing
    # src_id=int(data["data_subtype1"]),
    src_id=3,
    dst_id=1,
    # set_blocking=
    # False,  # Setting it to "True" causes issues when testing
)

with open("../db_info_hci.json") as f:
    data_discript = json.load(f)
    for synt in range(0, DURATION * SIMULATION_TIME):
        for name, data in data_discript.items():
            if data["data_id"] in [3023]:
                value = [random.random() for i in range(data["data_size"])]
                ins.send(
                    synt=synt,
                    id=data["data_id"],
                    value=value,
                    priority=3,
                )
        time.sleep(1 / SIMULATION_TIME)
        print("Simulation time -----------", synt)
ins.close()

# dst_id : 1 -> Habitat database
# dst_id : 0 -> Ground Database
# df = pd.read_csv("data.csv")
# for _, df in pd.read_csv("data.csv").groupby('time'):
#     for _, row in df.iterrows():
#         ins = api.API(local_ip="127.0.0.1",
#                       local_port=61234,
#                       remote_ip="127.0.0.1",
#                       remote_port=10000 + row['src'],
#                       src_id=row['src'],
#                       dst_id=1)
#         value = eval(row['data'])
#         ins.send(synt=row['time'],
#                  id=row['dataId'],
#                  value=value,
#                  priority=3,
#                  type=1)
#         ins.close()
#     time.sleep(1)
#     print("Simulation time -----------", row['time'])
