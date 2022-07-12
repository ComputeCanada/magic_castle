# Comparison of Cloud HPC Cluster Projects

| Name                              | Creator                                     | First public release date | Software license  |
| --------------------------------- | ------------------------------------------- | ------------------------- | ----------------- |
| [AWS ParallelCluster][1]          | AWS                                         | November 12, 2018         | Apache License v2 |
| [Azure CycleCloud][2]             | Microsoft                                   | October 17, 2018          | MIT License       |
| [Azure HPC On-Demand Platform][3] | Microsoft                                   | April 23, 2021            | MIT License       |
| [Cluster in the Cloud][4]         | Matt Williams  - University of Bristol      | March 27, 2019            | MIT License       |
| [ElastiCluster][5]                | Riccardo Murri - University of Zurich       | July 17, 2013             | GPLv3             |
| [Google HPC-Toolkit][6]           | Google                                      | May 26, 2022              | Apache License v2 |
| [Magic Castle][7]                 | Félix-Antoine Fortin - Compute Canada       | August 26, 2019           | MIT License       |
| [On-Demand Data Centre][9]        | Adaptive Computing                          | -                         | -                 |
| [Slurm on GCP][8]                 | SchedMD                                     | March 14, 2018            | Apache License v2 |

[1]: https://github.com/aws/aws-parallelcluster
[2]: https://github.com/Azure?q=cyclecloud&type=all&language=&sort=
[3]: https://github.com/Azure/az-hop
[4]: https://github.com/clusterinthecloud
[5]: https://github.com/elasticluster/elasticluster
[6]: https://github.com/GoogleCloudPlatform/hpc-toolkit
[7]: https://github.com/ComputeCanada/magic_castle
[8]: https://github.com/SchedMd/slurm-gcp
[9]: https://adaptivecomputing.com/cherry-services/on-demand-data-center-2/

## Supported cloud providers

| Name                         | Alibaba Cloud | AWS | Azure | Google Cloud | IBM Cloud | OpenStack | Oracle Cloud | OVH |
| ---------------------------- | ------------- | --- | ----- | ------------ | --------- | --------- | ------------ | --- |
| AWS ParallelCluster          | no            | yes | no    | no           | no        | no        | no           | no  |
| Azure CycleCloud             | no            | no  | yes   | no           | no        | no        | no           | no  |
| Azure HPC On-Demand Platform | no            | no  | yes   | no           | no        | no        | no           | no  |
| Cluster-in-the-Cloud         | no            | yes | no    | yes          | no        | no        | yes          | no  |
| ElastiCluster*               | no            | yes | yes   | yes          | no        | yes       | no           | -   |
| Google HPC-Toolkit           | no            | no  | no    | yes          | no        | no        | no           | no  |
| Magic Castle*                | no            | yes | yes   | yes          | no        | yes       | no           | yes |
| On-Demand Data Centre        | yes           | yes | yes   | yes          | no        | no        | yes          | no  |
| Slurm on GCP                 | no            | no  | no    | yes          | no        | no        | no           | no  |

\* The documentation provides instructions on how to add support for other cloud providers.


## Supported operating systems

| Name                         | CentOS 7 | CentOS 8 | Rocky Linux 8 | AlmaLinux 8 | Debian 10 | Ubuntu 18 | Ubuntu 20 | Windows 10 |
| ---------------------------- | -------- | -------- | ------------- | ----------- | --------- | --------- | --------- | ---------- |
| AWS ParallelCluster          | yes      | yes      | yes           | yes         | yes       | no        | yes       | no         |
| Azure CycleCloud             | yes      | yes      | yes           | yes         | yes       | no        | yes       | -          |
| Azure HPC On-Demand Platform | yes      | no       | no            | yes         | no        | yes       | no        | yes        |
| Google HPC-Toolkit           | yes      | no       | no            | no          | no        | no        | no        | no         |
| Cluster in the Cloud         | no       | yes      | no            | no          | no        | no        | no        | no         |
| ElastiCluster                | yes      | yes      | yes           | yes         | no        | no        | no        | no         |
| Magic Castle                 | yes      | yes      | yes           | yes         | no        | no        | no        | no         |
| On-Demand Data Centre        | -        | -        | -             | -           | -         | -         | -         | -          |
| Slurm on GCP                 | yes      | no       | no            | no          | yes       | no        | yes       | no         |


## Supported job schedulers

| Name                         | AwsBatch | Grid Engine | HTCondor | Moab | Open PBS | PBS Pro | Slurm |
| ---------------------------- | -------- | ----------- | -------- | ---- | -------- | ------- | ----- |
| AWS ParallelCluster          | yes      | no          | no       | no   | no       | no      | yes   |
| Azure CycleCloud             | no       | yes         | yes      | no   | no       | yes     | yes   |
| Azure HPC On-Demand Platform | no       | no          | no       | no   | yes      | no      | yes   |
| Google HPC-Toolkit           | no       | no          | no       | no   | no       | no      | yes   |
| Cluster in the Cloud         | no       | no          | no       | no   | no       | no      | yes   |
| ElastiCluster                | no       | yes         | no       | no   | no       | no      | yes   |
| Magic Castle                 | no       | no          | no       | no   | no       | no      | yes   |
| On-Demand Data Centre        | no       | no          | no       | yes  | no       | no      | no    |
| Slurm on GCP                 | no       | no          | no       | no   | no       | no      | yes   |


## Technologies

| Name                         | Infrastructure configuration  | Programming languages | Configuration management | Scientific software |
| ---------------------------- | ----------------------------- | --------------------- | ------------------------ | ------------------- |
| AWS ParallelCluster          | CLI generating YAML           | Python                | Chef                     | Spack               |
| Azure CycleCloud             | WebUI or CLI + templates      | Python                | Chef                     | Bring your own      |
| Azure HPC On-Demand Platform | YAML files + shell scripts    | Shell, Terraform      | Ansible, Packer          | CVMFS               |
| Cluster in the Cloud         | CLI generating Terraform code | Python, Terraform     | Ansible, Packer          | EESSI               |
| ElastiCluster                | CLI interpreting an INI file  | Python, Shell         | Ansible                  | Bring your own      |
| Google HPC-Toolkit           | CLI generating Terraform code | Go, Terraform         | Ansible, Packer          | Spack               |
| Magic Castle                 | Terraform modules             | Terraform             | Puppet                   | CC-CVMFS, EESSI     |
| On-Demand Data Centre        | -                             | -                     | -                        | -                   |
| Slurm GCP                    | Terraform modules             | Terraform             | Ansible, Packer          | Spack               |
