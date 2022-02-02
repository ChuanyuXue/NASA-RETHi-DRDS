import time
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
import scipy.io
import numpy as np
import api

FREQUENCY = 10
CYCLE = 8

patterns = ["*"]
ignore_patterns = None
ignore_directories = False
case_sensitive = True
my_event_handler = PatternMatchingEventHandler(patterns, ignore_patterns, ignore_directories, case_sensitive)


def send(event):
    print("%s file is detected.")
    if event.src_path.split('.')[-1] == 'mat':
        mat = scipy.io.loadmat(event.src_path)
        X = [x[:,1] for x in mat.values() if type(x) == np.ndarray]
        t = [x for x in mat.values() if type(x) == np.ndarray][0][:,0]
        data = np.concatenate([t.reshape(1,-1), X]).T
        data = data[::1000]

        api.init(
            local_ip="127.0.0.1",
            local_port=61234,
            to_ip="127.0.0.1",
            to_port=10002,
            client_id=2,
            server_id=1
        )

        count = 0
        for row in data:
            api.send(256, count, row[1:], 7, 4)
            time.sleep(1 / FREQUENCY)
        print("Sending period is finished.")

my_event_handler.on_created = send
my_event_handler.on_modified = send

path = "."
go_recursively = True
my_observer = Observer()
my_observer.schedule(my_event_handler, path, recursive=go_recursively)

my_observer.start()
my_observer.join()