#!/usr/bin/env python3
"""
Build a static list of Azure VM sizes using Azure MachineLearning API.
It creates a file called vmsizes.json in the current directory.
The file contains a dictionary with the following structure:
{
    "vmsize1": {
        "vcpus": 1,
        "ram": 1000,
        "gpus": 0
    },
}
"""

import requests
import argparse
import json

LOCATIONS = ['northcentralus', 'canadacentral', 'centralindia', 'uksouth', 'westus', 'centralus', 'eastasia', 'japaneast', 'japanwest', 'westus3', 'jioindiawest', 'germanywestcentral', 'switzerlandnorth', 'uaenorth', 'southafricanorth', 'norwayeast', 'eastus', 'northeurope', 'koreacentral', 'brazilsouth', 'francecentral', 'australiaeast', 'eastus2', 'westus2', 'westcentralus', 'southeastasia', 'westeurope', 'southcentralus']

api_version="2022-05-01"

def get_vmsizes(subscription_id, location, token):
    headers={'Content-Type':'application/json', 'Authorization': f'Bearer {token}'}
    url = f"https://management.azure.com/subscriptions/{subscription_id}/providers/Microsoft.MachineLearningServices/locations/{location}/vmSizes?api-version={api_version}"
    resp = requests.get(url, headers=headers)
    return resp

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate a list of Azure VM sizes')
    parser.add_argument('--subscription_id')
    parser.add_argument('--token')

    args = parser.parse_args()

    output = {}

    for location in LOCATIONS:
        resp = get_vmsizes(args.subscription_id, location, args.token)
        dict_ = resp.json()
        if "value" in dict_:
            data = dict_["value"]
            for item in data:
                key = item["name"]
                value = {
                    'vcpus': item['vCPUs'],
                    'ram': int(item['memoryGB'] * 1000),
                    'gpus': item['gpus']
                }
                if key in output and value != output[key]:
                    print(f"WARNING: {key} has conflicting values: {output[key]} and {value}")
                else:
                    output[key] = value
        else:
            print(f"WARNING: could not retrieve VM sizes for {location}")

    with open("vmsizes.json", "w") as f:
        json.dump(output, f, indent=2)

