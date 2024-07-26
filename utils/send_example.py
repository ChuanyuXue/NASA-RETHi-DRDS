import time
import pyapi.api as api

ins = api.API(
    local_ip="0.0.0.0",
    local_port=65533,
    remote_ip="127.0.0.1",
    remote_port=65531,
    src_id=1,
    dst_id=1,
)

ins.send(65000, 0, [15])

# for i in range(100):
#     ins.send(10001, i, [i])
#     print(i)
#     time.sleep(1)
