import pyapi.api as api

ins = api.API(
    local_ip="0.0.0.0",
    local_port=65533,
    remote_ip="127.0.0.1",
    remote_port=65531,
    src_id=1,
    dst_id=1,
)

# Request data(SPG DUST) whose ID == 3 at simulink time 1
last_time = -1
while True:
    re = ins.request(synt=0xFFFFFFFF, id=5004)
    # re = ins.request(synt=0xffffffff, id=129)
    # re = ins.request(synt=(0, 0xffff), id=5004)
    # from pprint import pprint
    if re.header.simulink_time != last_time:
        print(re.header.simulink_time)
        print(re.subpackets[0].header.length)
        print(list(re.subpackets[0].payload))
        last_time = re.header.simulink_time

# i = 0
# while True:
#   try:
#       for fdd in FDD_Data:
#           re = api.request(synt=0xffffffff, id=fdd.id)
#     data = reshape(re.payload, size)
#       for sys, data, thresh in zip(systems, data, thresh):
#           command[i] = hms(sys, data, thresh)
#       command_queue.append(commands) # 3
#       commands_to_agent = command_queue.pop(priority)
#     api.send(command_queue (MAXSIZE=size(FDD) = 5), to=c2_table1, time=sys.time)
#     api.send(commands_to_agent, to=c2_table2, time=sys.time)
#     i = i + shape(data, axis=0)
#   except:
#       break
