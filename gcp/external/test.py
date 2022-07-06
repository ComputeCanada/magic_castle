instance_types = ['e2-highcpu-32', 'e2-highcpu-16', 'e2-highcpu-2', 'e2-highcpu-4', 'e2-highcpu-8', 'e2-highmem-16',
                    'e2-highmem-2',
                    'e2-highmem-4', 'e2-highmem-8', 'e2-medium', 'e2-micro', 'e2-small', 'e2-standard-32',
                    'e2-standard-16',
                    'e2-standard-2', 'e2-standard-4', 'e2-standard-8', 'f1-micro', 'g1-small', 'n1-highcpu-16',
                    'n1-highcpu-2', 'n1-highcpu-32', 'n1-highcpu-4', 'n1-highcpu-64', 'n1-highcpu-8', 'n1-highcpu-96',
                    'n1-highmem-16', 'n1-highmem-2', 'n1-highmem-32', 'n1-highmem-4', 'n1-highmem-64', 'n1-highmem-8',
                    'n1-highmem-96', 'n1-standard-1', 'n1-standard-16', 'n1-standard-2',
                    'n1-standard-32', 'n1-standard-4', 'n1-standard-64', 'n1-standard-8', 'n1-standard-96',
                    'c2-standard-4', 'c2-standard-8', 'c2d-standard-2', 'c2d-standard-4', 'c2d-standard-8', 
                    'c2d-standard-16', 'c2d-standard-32', 'c2d-standard-56', 'c2d-standard-112', 'c2d-highcpu-2', 
                    'c2d-highcpu-4', 'c2d-highcpu-8', 'c2d-highcpu-16', 'c2d-highcpu-32', 'c2d-highcpu-56', 
                    'c2d-highcpu-112', 'c2d-highmem-2', 'c2d-highmem-4', 'c2d-highmem-8', 
                    'c2d-highmem-16', 'c2d-highmem-32', 'c2d-highmem-56', 'c2d-highmem-112',
                    'c2-standard-16', 'm1-ultramem-40', 'm1-ultramem-80', 'm1-ultramem-160',
                    'm1-megamem-96', 'c2-standard-30', 'c2-standard-60', 'm2-megamem-416', 'm2-ultramem-208', 'm2-ultramem-416',
                    'n2-standard-2', 'n2-standard-4', 'n2-standard-8', 'n2-standard-16', 'n2-standard-32',
                    'n2-standard-48', 'n2-standard-64', 'n2-standard-80', 'n2-standard-96', 'n2-standard-128',
                    'n2-highmem-2', 'n2-highmem-4',
                    'n2-highmem-8', 'n2-highmem-16', 'n2-highmem-32', 'n2-highmem-48', 'n2-highmem-64',
                    'n2-highmem-80', 'n2-highmem-96', 'n2-highmem-128', 'n2-highcpu-2', 'n2-highcpu-4', 'n2-highcpu-8', 'n2-highcpu-16', 'n2-highcpu-32',
                    'n2-highcpu-48', 'n2-highcpu-64', 'n2-highcpu-80', 'n2-highcpu-96', 'n2d-standard-2',
                    'n2d-standard-4',
                    'n2d-standard-8', 'n2d-standard-16', 'n2d-standard-32', 'n2d-standard-48', 'n2d-standard-64',
                    'n2d-standard-80', 'n2d-standard-96', 'n2d-standard-128', 'n2d-standard-224', 'n2d-highmem-2',
                    'n2d-highmem-4', 'n2d-highmem-8', 'n2d-highmem-16', 'n2d-highmem-32', 'n2d-highmem-48',
                    'n2d-highmem-64', 'n2d-highmem-80', 'n2d-highmem-96', 'n2d-highcpu-2', 'n2d-highcpu-4',
                    'n2d-highcpu-8', 'n2d-highcpu-16', 'n2d-highcpu-32', 'n2d-highcpu-48', 'n2d-highcpu-64',
                    'n2d-highcpu-80', 'n2d-highcpu-96', 'n2d-highcpu-128', 'n2d-highcpu-224', 'a2-highgpu-1g',
                    'a2-highgpu-2g', 'a2-highgpu-4g', 'a2-highgpu-8g', 'a2-megagpu-16g', 't2d-standard-1',
                    't2d-standard-2', 't2d-standard-4', 't2d-standard-8', 't2d-standard-16', 't2d-standard-32',
                    't2d-standard-48', 't2d-standard-60'
                    ]
from machine_type import get_vcpus_ram
for inst in instance_types:
    try:
        output = get_vcpus_ram(inst)
    except:
        output = {}
    print(inst, output)
