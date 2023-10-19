"""
Author: Chuanyu (skewcy@gmail.com)
websocket.py (c) 2023
Desc: description
Created:  2023-10-18T23:51:46.947Z
"""

import requests
import json

# Define the URL and the JSON dictionary
url = "http://localhost:9999/api/c2/10010"
json_dict = {
    "value0" : "1",
    "value1" : "2",
    "value2" : "3",
    "value3" : "4",
    "value4" : "5",
}

# Use the POST method to send the JSON dictionary
response = requests.post(url, json=json_dict)

# Check the HTTP response
if response.status_code == 200:
    print("Success:", response.json())
else:
    print("Failed:", response.status_code, response.text)
