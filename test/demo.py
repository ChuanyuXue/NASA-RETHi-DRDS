import test.api as api
import time

api.init(
    local_ip="127.0.0.1",
    local_port=65533,
    to_ip="127.0.0.1",
    to_port=65531,
    client_id=1,
    server_id=1
)

re = api.request(synt=2, id=3)
print(list(re.payload))

re = api.request(synt=(0, 45), id=3)
print(list(re.payload))

# ## -------------- synt 0 --------------------------
# synt = 0
# print("--------------- Time %d ----------------"%synt)

# table = 3
# value = [0.1]
# api.send(synt=synt, id=table, value = value)
# print("Clident send data %s to table %d"%(str(value), table))

# table = 4
# value = [0.1,0.1,0.1,0.1]
# api.send(synt=synt, id=table, value = value)
# print("Clident send data %s to table %d"%(str(value), table))
# time.sleep(1)

# # ## -------------- synt 1 ---------------------------
# synt = 1
# print("--------------- Time %d ----------------"%synt)

# table = 3
# value = [0.2]
# api.send(synt=synt, id=table, value = value)
# print("Clident send data %s to table %d"%(str(value), table))

# table = 3
# re = api.request(synt=(1), id=table)
# print("Clident request data at %s to table %d"%(str(0), table))
# print("Clident receive data %s to table %d"%(str(re["data"]), table))

# table = 3
# re = api.request(synt=(1, 2), id=table)
# print("Clident request data at %s to table %d"%(str((0,2)), table))
# print("Clident receive data %s to table %d"%(str(re["data"]), table))


# time.sleep(1)

# # ## ----------------- synt 2 to synt 10 ----------------

# synt = 2

# re = api.publish_register(3, synt)
# print("Client apply for publishing to table %d"%table)
# print("Client get reply %s"%re)

# re = api.subscribe_register(3, synt)
# print("Client apply for subscribing table %d"%table)
# print("Client get reply %s"%re)

# re = api.publish_register(4, synt)
# print("Client apply for publishing to table %d"%table)
# print("Client get reply %s"%re)

# re = api.subscribe_register(4, synt)
# print("Client apply for subscribing table %d"%table)
# print("Client get reply %s"%re)

# for synt in range(2, 11):
#     print("--------------- Time %d ----------------"%synt)
#     value = [synt/10]
#     table = 3
#     api.publish(table, synt, value = value, type=1)
#     print("Client publishs %s to table %d"%(value, table))
#     re = api.subscribe(table)
#     print("Client subscribe from table %d, get %s"%(table, str(re["data"])))

#     value = [synt/10, synt/10,synt/10,synt/10]
#     table = 4
#     api.publish(table, synt, value = value, type=1)
#     print("Client publishs %s to table %d"%(value, table))
#     re = api.subscribe(table)
#     print("Client subscribe from table %d, get %s"%(table, str(re["data"])))

#     time.sleep(1)
