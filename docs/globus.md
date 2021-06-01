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

1. In `main.tf`, add the following lines to `hieradata`:
    ```yaml
    profile::globus::base::globus_user: your_globus_username
    profile::globus::base::globus_password: your_globus_password
    ```
    Replace `your_globus_username` and `your_globus_password` by their respective value.
2. Apply the change : `terraform apply`.
3. Give Puppet a few minutes to setup Globus. You can confirm that
everything was setup correctly by looking at the tail of the puppet log on `login1`:
    ```
    journalctl -u puppet -f
    ```
4. If everything is correct, `globus-gridftp-server` and `myproxy-server`
services should be active. To confirm:
    ```
    sudo systemctl status globus-gridftp-server
    sudo systemctl status myproxy-server
    ```
5. If both services are active, in a browser, go to
https://app.globus.org/endpoints?scope=administered-by-me

Your endpoint should appear in the list and you should now be able to log in
by clicking on the activate button.