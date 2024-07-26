"""
There are two ways to send command to the subsystem.

1. Send command to the subsystem directly by setting the remote_ip (local ip of subsystem) and remote_port (local port of subsystem) in api.API(). Data is not 
   stored in the SQLight database but faster.
2. Send command to the database by setting remote_ip (host.docker.internal) and remote_port (65531) in api.API(), and make sure the dataID is 
   subscribed by the subsystem. ("habitatServer.Subscribe(4001, utils.SRC_AGT, 0, 1000)" in main.go). Data will be stored in the SQLight database but slower and safer.
"""

import time
import pyapi.api as api

ins = api.API(
    local_ip="0.0.0.0",
    local_port=65533,
    remote_ip="host.docker.internal",
    remote_port=65531,
    src_id=1,
    dst_id=6,
)

count = 0
time.sleep(5)
while True:
    value = [1, 1, 101130 + count, 5, 1, 2, 1, 29315, 30315]
    ins.send(4001, count, value)
    print("[Test] CommID:%d, Iteration: %d" % (4001, count), flush=True)
    print("Comman code -> ", value, flush=True)
    time.sleep(1)
    count += 1
