import api_old
import time
import json
import random

with open("db_info.json") as f:
    data_discript = json.load(f)

# server_id : 1 -> Habitat database
# server_id : 0 -> Ground Database
# Simulation for 600 seconds
for synt in range(600):
    for name, data in data_discript.items():
        api_old.init(
            local_ip="127.0.0.1",
            local_port=61234,
            to_ip="127.0.0.1",
            to_port=10000 + int(data['data_notes']),
            client_id=int(data['data_notes']),
            server_id=1
        )

        value = [random.random() for i in range(data['data_size'])]
        api_old.send(synt=synt, id=data['data_id'],
                 value=value, priority=3, type=1)
        api_old.close()
    time.sleep(1)
    print("Simulation time -----------", synt)
