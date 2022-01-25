import api
import time
import json
import random
import pandas as pd

with open("db_info.json") as f:
    data_discript = json.load(f)

# Simulation for 600 seconds
# for synt in range(600):
#     for name, data in data_discript.items():
#         api.init(
#             local_ip="127.0.0.1",
#             local_port=61234,
#             to_ip="127.0.0.1",
#             to_port=10000 + int(data['data_notes']),
#             client_id=int(data['data_notes']),
#             server_id=1
#         )

#         value = [random.random() for i in range(data['data_size'])]
#         api.send(synt=synt, id=data['data_id'],
#                  value=value, priority=3, type=1)
#         api.close()
#     time.sleep(1)
#     print("Simulation time -----------", synt)


for _, df in pd.read_csv("data.csv").groupby('time'):
    for _, row in df.iterrows():
        api.init(
            local_ip="127.0.0.1",
            local_port=61234,
            to_ip="127.0.0.1",
            to_port=10000 + row['src'],
            client_id=row['src'],
            server_id=1
        )
        value = eval(row['data'])
        api.send(synt=row['time'], id=row['dataId'],
                 value=value, priority=3, type=1)
        api.close()
    time.sleep(1)
    print("Simulation time -----------", row['time'])
