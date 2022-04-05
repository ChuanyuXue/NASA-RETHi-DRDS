import pyapi.api as api
import time
import json
import random
import pandas as pd
import json, random

with open("../db_info_press.json") as f:
    data_discript = json.load(f)

    # Simulation for 600 seconds
    for synt in range(99, 99 * 600 + 1, 100):
        for name, data in data_discript.items():
            if name != "Health_Management_System":
                ins = api.API(
                    local_ip="0.0.0.0",
                    local_port=61234,
                    to_ip="0.0.0.0",
                    # to_port=10000 + int(data['data_notes']),
                    # to_port=65533, # for local testing
                    to_port=10000 +
                    int(data["data_notes"]),  # for data service testing
                    client_id=int(data["data_notes"]),
                    server_id=1,
                    # set_blocking=
                    # False,  # Setting it to "True" causes issues when testing
                )

                value = [random.random() for i in range(data["data_size"])]
                ins.send(synt=synt,
                         id=data["data_id"],
                         value=value,
                         priority=3,
                         type=1)
                time.sleep(1e-3)
                ins.close()
                time.sleep(1e-6)
        time.sleep(1)
        print("Simulation time -----------", synt)

# server_id : 1 -> Habitat database
# server_id : 0 -> Ground Database
# df = pd.read_csv("data.csv")
# for _, df in pd.read_csv("data.csv").groupby('time'):
#     for _, row in df.iterrows():
#         ins = api.API(local_ip="127.0.0.1",
#                       local_port=61234,
#                       to_ip="127.0.0.1",
#                       to_port=10000 + row['src'],
#                       client_id=row['src'],
#                       server_id=1)
#         value = eval(row['data'])
#         ins.send(synt=row['time'],
#                  id=row['dataId'],
#                  value=value,
#                  priority=3,
#                  type=1)
#         ins.close()
#     time.sleep(1)
#     print("Simulation time -----------", row['time'])
