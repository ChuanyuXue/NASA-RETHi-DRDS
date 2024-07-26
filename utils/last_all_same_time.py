import json
import pyapi.api as api
import time
from threading import Thread


class ClientDRDS(Thread):

    def __init__(self, local_ip, local_port, remote_ip, remote_port, src_id, dst_id):
        self.conn = api.API(
            local_ip=local_ip,
            local_port=local_port,
            remote_ip=remote_ip,
            remote_port=remote_port,
            src_id=src_id,
            dst_id=dst_id,
        )
        self.buffer = None
        self.current_simulink_time = 0
        self.subscribed = False

        super().__init__()

    def run(self):
        if not self.subscribed:
            assert False, "Not subscribed"
        while True:
            data = self.conn.subscribe()
            if data is None:
                continue
            self._append_data(data)
            self.current_simulink_time = data.header.simulink_time

    ## Buffer cleaned every time when subscribe list updates
    def subscribe(self, all_subscribed_data: list):
        self.buffer = self._init_buffer(all_subscribed_data)
        for data_id in all_subscribed_data:
            ## By default subscribe from the beginning
            while self.conn.subscribe_register(data_id, 0) is None:
                time.sleep(0.1)
        self.subscribed = True

    def get_latest_all(self, all_subscribed_data: list):
        """
        Return:
        - time: int
        - latest_all: A list of 1-D vectors ordered by input all_subscribed_data
        """
        current_simulink_time = self.current_simulink_time
        latest_find = False

        while not latest_find and current_simulink_time > 0:
            latest_all = []
            for data_id in all_subscribed_data:
                if data_id not in self.buffer:
                    assert False, "Data ID not subscribed"
                if current_simulink_time not in self.buffer[data_id]["time"]:
                    current_simulink_time -= 1
                    break
                else:
                    latest_all.append(
                        self.buffer[data_id]["record"][
                            self.buffer[data_id]["time"].index(current_simulink_time)
                        ]
                    )
            else:
                latest_find = True
                self._clean_buffer_before_time(current_simulink_time)
                return current_simulink_time, latest_all
        return None, -1

    def _clean_buffer_before_time(self, time):
        for data_id in self.buffer:
            while (
                self.buffer[data_id]["time"] and self.buffer[data_id]["time"][0] < time
            ):
                self.buffer[data_id]["time"].pop(0)
                self.buffer[data_id]["record"].pop(0)

    def _check_subpacket_exist(self, data):
        if not data.subpackets:
            return False
        return True

    def _append_data(self, data):
        if not self._check_subpacket_exist(data):
            return
        data_id = data.subpackets[0].header.data_id
        simulink_time = data.header.simulink_time
        values = list(data.subpackets[0].payload)
        self.buffer[data_id]["time"].append(simulink_time)
        self.buffer[data_id]["record"].append(values)

    def _init_buffer(self, all_subscribed_data: list):
        buffer = {}
        for data_id in all_subscribed_data:
            buffer[data_id] = {}
            buffer[data_id]["time"] = []
            buffer[data_id]["record"] = []
        return buffer


def load_dataID(path):
    all_data = []
    with open(path) as f:
        data_discript = json.load(f)
        for name, data in data_discript.items():
            all_data.append(data["data_id"])
    return all_data


## How to use this API?
if __name__ == "__main__":
    ## Initialize client
    client = ClientDRDS(
        local_ip="0.0.0.0",
        local_port=65533,
        remote_ip="127.0.0.1",
        remote_port=65531,
        src_id=1,
        dst_id=1,
    )
    ## [client.subscribe()]: Let client subscribe required data
    request_id = load_dataID("../db_info_v6.json")
    client.subscribe(request_id)
    client.start()

    ## [client.get_latest_all()]: Get latest data with same timestamp
    count = 0
    while True:
        t, values = client.get_latest_all(request_id)
        print(f"[GET LATEST DATA]: time-{t}, data-{values}", flush=True)
        time.sleep(1)
        client.conn.send(65000, count, [15])
        count += 1
    client.join()
