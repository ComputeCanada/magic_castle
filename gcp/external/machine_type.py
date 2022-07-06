import json
import sys

MACHINE_TYPES = {
    "e2-micro": {"vcpus": 2, "ram": 1000},
    "e2-small": {"vcpus": 2, "ram": 2000},
    "e2-medium": {"vcpus": 2, "ram": 4000},
    "f1-micro": {"vcpus": 1, "ram": 600},
    "g1-small": {"vcpus": 1, "ram": 1700},
}

def get_vcpus_ram(machine_type):
    output = {}    
    if machine_type in MACHINE_TYPES:
        output = MACHINE_TYPES[machine_type]
    else:
        machine_type = machine_type.removesuffix('-ext')
        pre, mid, suf = machine_type.split('-')
        if pre == 'custom':
            # custom-NUMBER_OF_CPUS-AMOUNT_OF_MEMORY_MB
            output['vcpus'] = int(mid)
            output['ram'] = int(suf)
        elif pre in ('e2', 'n2', 'n2d', 't2d', 'c2', 'c2d'):
            if mid in ('standard', 'highcpu', 'highmem'):
                ram_per_cpus = {
                    'standard': 4000,
                    'highmem': 8000,
                    'highcpu': 1000,
                }    
                output['vcpus'] = int(suf)
                output['ram'] = ram_per_cpus[mid] * int(suf) 
        elif pre == 'n1':
            ram_per_cpus = {
                'standard': 3750,
                'highmem': 6500,
                'highcpu': 900,
            }        
            output['vcpus'] = int(suf)
            output['ram'] = ram_per_cpus[mid] * int(suf)
        elif pre == 'm1':
            if mid == "ultramem":
                base_vcpus = 40
                base_ram = 961
            elif mid == "megamem":
                base_vcpus = 96
                base_ram = 1433
            output['vcpus'] = int(suf)
            output['ram'] = base_ram * int(suf) // base_vcpus
        elif pre == 'm2':
            if mid == "ultramem":
                base_vcpus = 208
            elif mid == "megamem":
                base_vcpus = 416
            base_ram = 5888
            output['vcpus'] = int(suf)
            output['ram'] = base_ram * int(suf) // base_vcpus    
        elif pre == "a2":
            # remove the 'g' suffix
            suf = suf[:-1]
            if mid == "highgpu":
                output['vcpus'] = int(suf) * 12
            elif mid == "megagpu":
                output['vcpus'] = 96
            output['ram'] = int(suf) * 85000
            output['gpus'] = int(suf)
    return output

if __name__ == "__main__":
    inputs = json.load(sys.stdin)
    try:
        output = get_vcpus_ram(inputs['machine_type'])
    except:
        output = {"vcpus": None, "ram": None}
    for key in output:
        output[key] = str(output[key])
    print(json.dumps(output))