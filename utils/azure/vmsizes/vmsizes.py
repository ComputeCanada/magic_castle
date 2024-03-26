#!/usr/bin/env python3
"""
Build a static list of Azure VM sizes from az CLI list-skus output.
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
import sys
import json

if __name__ == "__main__":
    try:
        data = json.load(sys.stdin)
    except:
        print(f"Usage: az vm list-skus --resource-type virtualMachines | {sys.argv[0]}")
        sys.exit()
    output = {}
    for item in data:
        if item["resourceType"] == "virtualMachines":
            key = item["name"]
            caps = { el["name"]:el["value"] for el in item["capabilities"] }
            value = {
                "vcpus": int(caps.get("vCPUsAvailable", caps["vCPUs"])),
                "ram":   int(float(caps.get("MemoryGB"))* 1000),
                "gpus":  int(caps.get("GPUs", 0))
            }
            if key in output and value != output[key]:
                print(
                    f"WARNING: {key} has conflicting values: {output[key]} and {value}"
                )
            else:
                output[key] = value

    with open("vmsizes.json", "w") as f:
        json.dump(output, f, indent=2)
