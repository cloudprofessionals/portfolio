import requests
import json
from urllib3 import disable_warnings

disable_warnings()


def get_tickets(data: dict):
    headers = {"Accept": "application/json", "x-api-key": "${api_key}"}

    url = "${api_endpoint}/tickets/report"

    response = requests.get(url, headers=headers, verify=False, params=data).json()

    return json.dumps(response, indent=4)


data = {
    "service_start": "2021-03-01",
    "service_end": "2021-03-02",
}

res = get_tickets(data)

print(res)
# print('Total record: ', size)
