import time
import pyapi.api as api

ins = api.API(local_ip="0.0.0.0",
              local_port=65533,
              to_ip="127.0.0.1",
              to_port=65531,
              client_id=1,
              server_id=6)

count = 0
value = 1001000300512129315303150000000000000000
while True:
    ins.send(40001, count, [value])
    print("[Test] CommID:%d, Iteration: %d" % (40001, count), flush=True)
    print("Comman code -> ", value, flush=True)
    time.sleep(1)
    count += 1

# for i in range(100):
#     ins.send(10001, i, [i])
#     print(i)
#     time.sleep(1)

# import time
# while True:
#     time.sleep(1)
#     print("[?]")