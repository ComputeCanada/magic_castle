### X.X puppetenv_branch (**optional**)

**default value**: `master`

Package installation and configuration - provisioning - of the cluster
is mainly done by [Puppet](https://en.wikipedia.org/wiki/Puppet_(software)).
Magic Castle provides Puppet environments as a git repo.
Each environment is defined by three files:
* `data/common.yaml.tmpl`: define values for module variables as a Terraform template
* `manifests/site.pp`: identify the modules for each hostname
* `Puppetfile`: identify the source of each module

There are four branches currently available:
* `basic`: SLURM cluster with NFS home, scratch and project;
* `cvmfs`: `basic` + Compute Canada CVMFS;
* `globus`: `cvmfs` + Globus Endpoint on the login node;
* `master`: `globus` + JupyterHub on the login node.

To get more details on the configuration of each host per arrangement,
look at the [`puppet_env` repo](https://git.computecanada.ca/magic_castle/puppet_env/tree/master).

If the variable is left undefined, the arrangement will be `master`.

#### X.X.1 Post Build Modification Effect

Modifying this variable after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.