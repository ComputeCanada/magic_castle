# Comparison of Cloud HPC Cluster Projects

| Name                 | Creator                                     | First public release date | Software license  |
| -------------------- | ------------------------------------------- | ------------------------- | ----------------- |
| AWS ParallelCluster  | AWS                                         | November 12, 2018         | Apache License v2 |
| Azure CycleCloud     | Microsoft                                   | October 17, 2018          | MIT License       |
| Cluster-in-the-Cloud | Matt Williams  - University of Bristol      | March 27, 2019            | MIT License       |
| ElastiCluster        | Riccardo Murri - University of Zurich       | July 17, 2013             | GPLv3             |
| Google HPC-Toolkit   | Google                                      | May 26, 2022              | Apache License v2 |
| Magic Castle         | Félix-Antoine Fortin - Compute Canada       | August 26, 2019           | MIT License       |
| Slurm on GCP         | SchedMD                                     | March 14, 2018            | Apache License v2 |


## Supported cloud providers

| Name                 | Alibaba Cloud | AWS | Azure | Google Cloud | IBM Cloud | OpenStack | Oracle Cloud | OVH |
| -------------------- | ------------- | --- | ----- | ------------ | --------- | --------- | ------------ | --- |
| AWS ParallelCluster  | no            | yes | no    | no           | no        | no        | no           | no  |
| Azure CycleCloud     |  no           | no  | yes   | no           | no        | no        | no           | no  |
| Cluster-in-the-Cloud | no            | yes | no    | yes          | no        | no        | yes          | no  |
| ElastiCluster*       | no            | yes | yes   | yes          | no        | yes       | no           | -   |
| Google HPC-Toolkit   | no            | no  | no    | yes          | no        | no        | no           | no  |
| Magic Castle*        | no            | yes | yes   | yes          | no        | yes       | no           | yes |
| Slurm on GCP         | no            | no  | no    | yes          | no        | no        | no           | no  |

* The documentation provides instructions on how to add support for other cloud providers.

## Supported operating systems

| Name                 | RHEL 7 | CentOS 7 | RHEL 8 | CentOS 8 | Rocky Linux 8 | AlmaLinux 8 | Debian 10 | Ubuntu 20 |
| -------------------- | ------ | -------- | ------ | -------- | ------------- | ----------- | --------- | --------- |
| AWS ParallelCluster  | yes    | yes      | yes    | yes      | yes           | yes         | yes       | yes       |
| Azure CycleCloud     | yes    | yes      | yes    | yes      | yes           | yes         | yes       | yes       |
| Google HPC-Toolkit   | yes    | yes      | no     | no       | no            | no          | no        | no        |
| Cluster-in-the-Cloud | no     | no       | yes    | yes      | no            | no          | no        | no        |
| ElastiCluster        | yes    | yes      | yes    | yes      | yes           | yes         | no        | no        | 
| Magic Castle         | yes    | yes      | yes    | yes      | yes           | yes         | no        | no        |
| Slurm on GCP         | yes    | yes      | no     | no       | no            | no          | yes       | yes       |


## Technologies 

| Name                  | How infra is configured       | Programming languages | Configuration management | Scientific software management  |
| --------------------- | ----------------------------- | --------------------- | ------------------------ | ------------------------------  |
| AWS ParallelCluster   | CLI generating YAML           | Python                | Chef                     | Spack                           |
| Cluster-in-the-Cloud  | CLI generating Terraform code | Python, Terraform     | Ansible, Packer          | EESSI                           |
| ElastiCluster         | CLI interpreting an INI file  | Python, Shell         | Ansible                  | Bring your own                  |
| Google HPC-Toolkit    | CLI generating Terraform code | Go, Terraform         | Ansible, Packer          | Spack                           |
| Magic Castle          | Terraform modules             | Terraform             | Puppet                   | CC-CVMFS, EESSI                 |
| Slurm GCP             | Terraform modules             | Terraform             | Ansible, Packer          | Spack                           |
