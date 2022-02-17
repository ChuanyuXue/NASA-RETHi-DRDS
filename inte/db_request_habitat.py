import pyapi.api as api

ins = api.API(
    local_ip="0.0.0.0",
    local_port=65533,
    to_ip="127.0.0.1",
    to_port=65531,
    client_id=1,
    server_id=1
)


# Request data(SPG DUST) whose ID == 3 at simulink time 1
re = ins.request(synt=0xffffffff, id=3)
# re = ins.request(synt=(0, 0xffff), id=3)
# from pprint import pprint
print(re.header.simulink_time)
print(re.header.length)
print(re.payload)

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
