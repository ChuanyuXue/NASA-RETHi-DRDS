import time
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
import scipy.io
import numpy as np
import pyapi.api as api

SAMPLE_RATE = 0.01
CYCLE = 8

patterns = ["*"]
ignore_patterns = None
ignore_directories = False
case_sensitive = True
my_event_handler = PatternMatchingEventHandler(
    patterns, ignore_patterns, ignore_directories, case_sensitive)


def send(event):
    if event.src_path.split('.')[-1] == 'mat':
        print("Updates on %s is detected" % event.src_path)
        try:
            mat = scipy.io.loadmat(event.src_path)
            X = [x[:, 1] for x in mat.values() if type(x) == np.ndarray]
            t = [x for x in mat.values() if type(x) == np.ndarray][0][:, 0]
            data = np.concatenate([t.reshape(1, -1), X]).T
            data = data[:: int(1 / SAMPLE_RATE)]

            ins = api.API(
                local_ip="127.0.0.1",
                local_port=61234,
                to_ip="127.0.0.1",
                to_port=10002,
                client_id=2,
                server_id=1
            )

            for row in data:
                ins.send(256, int(row[0] * 1e8), row[1:], 7, 4)
                time.sleep(CYCLE / len(data))
            ins.close()

        except OSError:
            print("Cound not read %s" % event.src_path)


class Trigger:
    def __init__(self, path) -> None:
        self.src_path = path


if __name__ == "__main__":
    send(Trigger("Hammer_Test_1_01.mat"))
    my_event_handler.on_created = send
    my_event_handler.on_modified = send

    path = "."
    go_recursively = True
    my_observer = Observer()
    my_observer.schedule(my_event_handler, path, recursive=go_recursively)

    my_observer.start()
    my_observer.join()
