import json
import numpy as np
from pyapi.utils import *


def generate_info(dataid, name, type, subtype, subtype2, rate, size, uint,
                  notes):
    data = {
        name: {
            "data_id": dataid,
            "data_name": name,
            "data_type": type,
            "data_subtype1": subtype,
            "data_subtype2": subtype2,
            "data_rate": rate,
            "data_size": size,
            "data_unit": uint,
            "data_notes": "%d" % notes
        }
    }
    return data


result = {}

for i in range(1, 13):
    result.update(
        generate_info(128 + i, "meas (signal %d)" % i, TYPE_SENSOR, TYPE_OTHER,
                      TYPE_OTHER, 1, 1, 'n/a', SRC_ECLSS))

for i in range(5004, 5017):
    result.update(
        generate_info(i, "meas (signal %d)" % i, TYPE_FDD, TYPE_OTHER,
                      TYPE_OTHER, 1, 3, 'n/a', SRC_ECLSS))

json_string = json.dumps(data)
<<<<<<< HEAD
with open('db_info_press.json', 'w') as outfile:
=======
with open('db_info_v6.json', 'w') as outfile:
>>>>>>> v6_aggre
    outfile.write(json_string)