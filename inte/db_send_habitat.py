import time
import pyapi.api as api

ins = api.API(local_ip="0.0.0.0",
              local_port=65533,
              to_ip="127.0.0.1",
              to_port=20006,
              client_id=1,
              server_id=6)

ins.send(10001, 12345, [15])

# for i in range(100):
#     ins.send(10001, i, [i])
#     print(i)
#     time.sleep(1)
