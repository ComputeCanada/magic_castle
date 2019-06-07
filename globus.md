# Globus Endpoint in Magic Castle

A Globus Endpoint can be configured automatically for a Magic Castle cluster.
There are however a few manual steps to accomplish.


## Requirements
### Create a Globus ID Account

We will have to store your Globus credentials in a YAML file on the cluster in
clear. While the file is only readable by root, if you prefer to not use your 
personal globus, we recommend you create a dummy one at:

[https://www.globusid.org/create](https://www.globusid.org/create)

### DNS

If your cluster hostname is not registered in the domain records of your DNS,
you will have to register it manually. Make sure you use the same domain name
as the one you provided in Terraform main file.

## Setup

On the login node `login01`:
1. Edit the file `/etc/puppetlabs/puppet/hieradata/data.yaml` with sudo rights
and add the following lines:
```
profile::globus::base::globus_user: your_globus_username
profile::globus::base::globus_password: your_globus_password
```
Replace `your_globus_username` and `your_globus_password` by their respective
value.
2. The globus server installation is triggered when there modifications to the
file `/etc/globus-connect-server.conf`. Open that file, and add an empty line
at the end.
3. Reboot the login node: `sudo reboot -n`.
4. Give Puppet a few minutes to setup Globus after reboot. You can confirm that
everything was setup correctly by looking at the tail of the puppet log:
```
tail -n 30 /var/log/puppetlabs/puppet/puppet.log
```
5. If everything is correct, `globus-gridftp-server` and `myproxy-server`
services should be active. To confirm:
```
sudo systemctl status globus-gridftp-server
sudo systemctl status myproxy-server
```
6. If both services are active, in a browser, go to 
[https://app.globus.org/endpoints?scope=administered-by-me](https://app.globus.org/endpoints?scope=administered-by-me)
7. Click on your endpoint.
8. Click on the `Server` tab.
9. At the bottom of the page, there is text field named "Subject DN". Copy the content, it should look like this:
```
/C=US/O=Globus Consortium/OU=Globus Connect Service/CN=xxxx-x-xxx-xxx-xxxxxx
```
10. The first section of the Server page is named "Identity Provider". Click on the `Edit Identity Provider` button.
11. In the DN field of Edit Identity Provider, paste the content you copied from "Subject DN".
12. Click on Save Changes.

You should now be able to log in your Globus Endpoint with your cluster guest accounts' username and password.