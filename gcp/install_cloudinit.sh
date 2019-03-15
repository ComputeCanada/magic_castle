#!/bin/bash
if yum -q list installed "cloud-init" >/dev/null 2>&1; then
    true
else
    sudo yum -y install cloud-init
    sudo reboot
fi
rm -f /etc/dhcp/dhclient.d/google_hostname.sh