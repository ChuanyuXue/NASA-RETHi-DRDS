import numpy as np
import sys
import json



def thermal_power_dt(
        current_time,
        current_temperature,
        battery_state_of_charge,
        current_hvac_mode,
        current_heating_setpoint,
        current_cooling_setpoint,
        time_of_new_setpoint,
        new_hvac_mode,
        new_heating_setpoint,
        new_cooling_setpoint,
        final_time,
        num_time_steps=100,
        num_samples=1000
):
    ts = np.linspace(current_time, final_time, num_time_steps)
    temperatures = np.random.randn(num_samples, num_time_steps)
    battery_charge = np.random.randn(num_samples, num_time_steps)
    hvac_power = np.random.randn(num_samples, num_time_steps)
    tq_500, tq_025, tq_975 = np.percentile(temperatures, [50, 2.5, 97.5], axis=0)
    tb_500, tb_025, tb_975 = np.percentile(battery_charge, [50, 2.5, 97.5], axis=0)
    tp_500, tp_025, tp_975 = np.percentile(hvac_power, [50, 2.5, 97.5], axis=0)
    quantiles = {
        'temperature': {
            'median': tq_500,
            'lower': tq_025,
            'upper': tq_975
        },
        'battery_charge': {
            'median': tb_500,
            'lower': tb_025,
            'upper': tb_975
        },
        'hvac_power': {
            'median': tp_500,
            'lower': tp_025,
            'upper': tp_975
        }
    }
    return ts, temperatures, hvac_power, battery_charge, quantiles


def json_serialize_default(obj):
    if isinstance(obj, np.ndarray):
        return obj.tolist()
    raise TypeError('Not serializable')

if __name__ == "__main__":
    # params_arg = '{"current_time":0,"current_temperature":0,"battery_state_of_charge":0,"current_hvac_mode":0,"current_heating_setpoint":0,"current_cooling_setpoint":0,"time_of_new_setpoint":0,"new_hvac_mode":0,"new_heating_setpoint":0,"new_cooling_setpoint":0,"final_time":0,"num_time_steps":10,"num_samples":10}'
    # params = json.loads(params_arg)
    params = json.loads(sys.argv[1])

    ts, temperatures, hvac_power, battery_charge, quantiles = thermal_power_dt(
        params["current_time"],
        params["current_temperature"],
        params["battery_state_of_charge"],
        params["current_hvac_mode"],
        params["current_heating_setpoint"],
        params["current_cooling_setpoint"],
        params["time_of_new_setpoint"],
        params["new_hvac_mode"],
        params["new_heating_setpoint"],
        params["new_cooling_setpoint"],
        params["final_time"],
        num_time_steps=params["num_time_steps"],
        num_samples=params["num_samples"]
    )
    
    output = {
        "ts": ts,
        "temperatures": temperatures,
        "hvac_power": hvac_power,
        "battery_charge": battery_charge,
        "quantiles": quantiles,
    }
    print(json.dumps(output,default=json_serialize_default))
