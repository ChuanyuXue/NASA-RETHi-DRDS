import api

api.init(
    local_ip = "127.0.0.1",
    local_port= 65533,
    to_ip = "127.0.0.1",
    to_port = 65531,
    client_id = 1,
    server_id = 0
)


## Request data(SPG DUST) whose ID == 3 at simulink time 1
# re = api.request(synt=0xffffffff, id=3)
re = api.request(synt=(0, 0xffff), id=3)
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
#     command = hms(system, fdd_data, thresholds)
#     api.send(command)
#     i = i + shape(data, axis=0)
#   except:
#       break