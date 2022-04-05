import json
import numpy as np

data = {
    "DATA-%d" % i: {
        "data_id": i + 3,
        "data_name": "DATA-%d" % i,
        "data_type": 1,
        "data_subtype1": 255,
        "data_subtype2": 255,
        "data_rate": 1,
        "data_size": 50,
        "data_unit": "NaN",
        "data_notes": "%d" % np.random.randint(2, 8)
    }
    for i in range(256)
}

json_string = json.dumps(data)
with open('db_info_press.json', 'w') as outfile:
    outfile.write(json_string)