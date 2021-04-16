# Globus Endpoint in Magic Castle

A Globus Endpoint can be configured automatically for a Magic Castle cluster.
There are however a few manual steps to accomplish.

## Requirements
### Create a Globus ID Account

We will store your Globus credentials in a YAML file on the cluster in
clear. While the file is only readable by root, if you prefer to not use your
personal globus, we recommend you create a dummy one at:

[https://www.globusid.org/create](https://www.globusid.org/create)

### DNS

The Globus Puppet module relies heavily on the dns submodule of Magic Castle
since it registers subdomains and create SSL certificates that are required
by Globus. If you plan to install Globus without first activating the dns
submodule, you are on your own.

## Setup

1. Connect to the Puppet main server from within the cluster: `ssh puppet`
2. Open the file `/etc/puppetlabs/code/environments/production/data/common.yaml` with sudo rights
and add the following lines:
    ```
    profile::globus::base::globus_user: your_globus_username
    profile::globus::base::globus_password: your_globus_password
    ```
Replace `your_globus_username` and `your_globus_password` by their respective value.

On `login1`:
1. Restart puppet : `sudo systemctl restart puppet`.
2. Give Puppet a few minutes to setup Globus. You can confirm that
everything was setup correctly by looking at the tail of the puppet log:
    ```
    sudo journalctl -u puppet -f
    ```
3. If everything is correct, `globus-gridftp-server` and `myproxy-server`
services should be active. To confirm:
    ```
    sudo systemctl status globus-gridftp-server
    sudo systemctl status myproxy-server
    ```
4. If both services are active, in a browser, go to
https://app.globus.org/endpoints?scope=administered-by-me

Your endpoint should appear in the list and you should now be able to log in
by clicking on the activate button.