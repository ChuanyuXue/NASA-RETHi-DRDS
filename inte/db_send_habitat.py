import time
import pyapi.api as api

ins = api.API(local_ip="0.0.0.0",
              local_port=65533,
              to_ip="192.168.50.112",
              to_port=10012,
              client_id=1,
              server_id=1)

for i in range(100):
    ins.send(9, i, [0])
    time.sleep(1)
