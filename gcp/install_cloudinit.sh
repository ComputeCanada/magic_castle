#!/bin/bash
rm -f /etc/dhcp/dhclient.d/google_hostname.sh
if [ ! -f /etc/cloud/cloud-init.disabled ]; then
    if  [ ! -f /usr/bin/cloud-init ]; then
        # Try to install cloud-init every 5 seconds for 12 times.
        for i in $(seq 12); do
            yum -y install cloud-init && break
            sleep 5
        done
    fi
    # Verify installation was successful
    if  [ -f /usr/bin/cloud-init ]; then
        systemctl disable cloud-init
        touch /etc/cloud/cloud-init.disabled
        cloud-init init --local
        cloud-init init
        cloud-init modules --mode=config
        cloud-init modules --mode=final
    else
        echo "Problem installing cloud-init. Verify network connectivity and reboot."
    fi
elif [ -f /usr/bin/cloud-init ]; then
    yum -y remove cloud-init
fi
