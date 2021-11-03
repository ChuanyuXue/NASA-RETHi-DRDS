import api

api.init(
    client_ip ="127.0.0.1",
    client_port = 10002,
    server_ip = "127.0.0.1",
    server_port = 10001,
    client_id = 1,
    server_id = 0
)

## -------------- Time 0 --------------------------
time = 0

table = 3
value = [0.1]
api.send(synt=time, id=table, value = value)
print("Time %d: Client send asynchronous data %s to table %d"%(time, str(value), table))

table = 4
value = [0.1,0.1,0.1,0.1]
api.send(synt=time, id=table, value = value)
print("Time %d: Client send asynchronous data %s to table %d"%(time, str(value), table))

# ## -------------- Time 1 ---------------------------
time = 1

table = 3
value = [0.2]
api.send(synt=time, id=table, value = value)
print("Time %d: Client send asynchronous data %s to table %d"%(time, str(value), table))

table = 3
re = api.request(synt=0, id=table)
print("Time %d: Client request asynchronous data %s from table %d"%(time, str(re), table))

table = 3
re = api.request(synt=(0,2), id=table)
print("Time %d: Client request asynchronous data %s from table %d"%(time, str(re), table))

# ## ----------------- Time 2 to Time 10 ----------------

time = 2
re = api.publish_register(3, 2)
print("Time %d: Client apply for publishing to table %d, get reply %s"%(time, table, str(re)))

re = api.subscribe_register(3, 2)
print("Time %d: Client apply for subscribing to table %d from time %d, get reply %s"%(time, table, 0, str(re)))

for time in range(2, 11):
    api.publish(3, time, value = [time/10])
    print("Time %d: Client publishs to table %d"%(time, table))
    re = api.subscribe(3)
    print("Time %d: Client subscribe from table %d, get %s"%(time, table, str(re)))

