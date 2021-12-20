import api
import time
import random

src_list = [2, 3, 4, 5, 6, 7]

data_id = {
    2: [6],
    3: [3, 7],
    4: [4, 5],
    5: [8],
    6: [],
    7: [],
}

data_size = {
    3: 4,
    4: 50,
    5: 50,
    6: 1,
    7: 1,
    8: 1,
}

# Simulation for 600 seconds
for synt in range(600):
    for src in src_list:
        api.init(
            local_ip="127.0.0.1",
            local_port=10002,
            to_ip="127.0.0.1",
            to_port=10000 + src,
            client_id=src,
            server_id=1
        )
        for table in data_id[src]:
            value = [random.random() for i in range(data_size[table])]
            api.send(synt=synt, id=table, value=value, priority=3, type=1)
    time.sleep(1)
    print("Simulation time -----------", synt)
