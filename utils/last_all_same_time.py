import json
import pyapi.api as api
import time
from threading import Thread


class ClientDRDS(Thread):

    def __init__(self, local_ip, local_port, to_ip, to_port, client_id,
                 server_id):
        self.conn = api.API(local_ip=local_ip,
                            local_port=local_port,
                            to_ip=to_ip,
                            to_port=to_port,
                            client_id=client_id,
                            server_id=server_id)
        self.buffer = None
        self.current_simulink_time = 0
        self.subscribed = False

        super().__init__()

    def run(self):
        if not self.subscribed:
            assert False, "Not subscribed"
        while True:
            data = self.conn.subscribe()
            self._append_data(data)
            self.current_simulink_time = data.header.simulink_time

    ## Buffer cleaned every time when subscribe list updates
    def subscribe(self, all_subscribed_data: list):
        self.buffer = self._init_buffer(all_subscribed_data)
        for data_id in all_subscribed_data:
            ## By default subscribe from the beginning
            self.conn.subscribe_register(data_id, 0)
        self.subscribed = True

    def get_latest_all(self, all_subscribed_data: list):
        '''
        Return:
        - time: int
        - latest_all: A list of 1-D vectors ordered by input all_subscribed_data
        '''
        current_simulink_time = self.current_simulink_time
        latest_find = False

        while not latest_find and current_simulink_time > 0:
            latest_all = []
            for data_id in all_subscribed_data:
                if data_id not in self.buffer:
                    assert False, "Data ID not subscribed"
                if current_simulink_time not in self.buffer[data_id]['time']:
                    current_simulink_time -= 1
                    break
                else:
                    latest_all.append(self.buffer[data_id]['record'][
                        self.buffer[data_id]['time'].index(
                            current_simulink_time)])
            else:
                latest_find = True
                self._clean_buffer_before_time(current_simulink_time)
                return current_simulink_time, latest_all
        return None, -1
    
    def _clean_buffer_before_time(self, time):
        for data_id in self.buffer:
            while self.buffer[data_id]['time'] and self.buffer[data_id]['time'][0] < time:
                self.buffer[data_id]['time'].pop(0)
                self.buffer[data_id]['record'].pop(0)

    def _append_data(self, data):
        data_id = data.subpackets[0].header.data_id
        simulink_time = data.header.simulink_time
        values = list(data.subpackets[0].payload)
        self.buffer[data_id]['time'].append(simulink_time)
        self.buffer[data_id]['record'].append(values)

    def _init_buffer(self, all_subscribed_data: list):
        buffer = {}
        for data_id in all_subscribed_data:
            buffer[data_id] = {}
            buffer[data_id]['time'] = []
            buffer[data_id]['record'] = []
        return buffer


def load_dataID(path):
    all_data = []
    with open(path) as f:
        data_discript = json.load(f)
        for name, data in data_discript.items():
            all_data.append(data['data_id'])
    return all_data


## How to use this API?
if __name__ == '__main__':
    ## Initialize client
    client = ClientDRDS(local_ip="0.0.0.0",
                        local_port=65533,
                        to_ip="127.0.0.1",
                        to_port=65531,
                        client_id=1,
                        server_id=1)
    ## [client.subscribe()]: Let client subscribe required data
    request_id = load_dataID("../db_info_v6.json")
    client.subscribe(request_id)
    client.start()

    ## [client.get_latest_all()]: Get latest data with same timestamp
    while True:
        t, values = client.get_latest_all(request_id)
        print(f"[GET LATEST DATA]: time-{t}, data-{values}", flush=True)
        time.sleep(1)
    client.join()
