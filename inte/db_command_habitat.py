import time
import pyapi.api as api

# rawData = append(
#     rawData,
#     msg.DoOrCancel,
#     msg.CommandID,
#     msg.TimeToStart,
#     msg.SystemID,
#     msg.CommandType,
#     msg.ZoneID,
#     msg.Mode,
#     msg.TSpHeat,
#     msg.TSpCool,
# )

ins = api.API(local_ip="0.0.0.0",
              local_port=65533,
              to_ip="host.docker.internal",
              to_port=65531,
              client_id=1,
              server_id=6)

count = 0
time.sleep(5)
while True:
    value = [1, 1, 101130 + count, 5, 1, 2, 1, 29315, 30315]
    ins.send(4001, count, value)
    print("[Test] CommID:%d, Iteration: %d" % (4001, count), flush=True)
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