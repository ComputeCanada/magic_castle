#!/bin/bash
ZIP_FILE="etc_puppetlabs.zip"
ZIP_DIR=${ZIP_FILE%.zip}
GIT_URL="${1}"
GIT_REF="${2}"
ORIGIN="${3}"

if [ ! -f /usr/bin/go-getter ]; then
    curl -L -O https://releases.hashicorp.com/go-getter/1.8.9/go-getter_1.8.9_linux_amd64.zip
    unzip go-getter_1.8.9_linux_amd64.zip go-getter -d /usr/bin
    rm -f go-getter_1.8.9_linux_amd64.zip
fi

if [[ "${ORIGIN}" == "tf" ]] && [[ $(cloud-init status) != "status: done" ]]; then
    exit
fi

if [ ! -e "/etc/puppetlabs/code/environments/${GIT_REF}" ]; then
    rm -rf /etc/puppetlabs/code/environments/production
    /usr/bin/go-getter git:://${GIT_URL}?ref=${GIT_REF} /etc/puppetlabs/code/environments/${GIT_REF}
    ln -s /etc/puppetlabs/code/environments/${GIT_REF} /etc/puppetlabs/code/environments/production
    ln -s /etc/puppetlabs/code/environments/production /etc/puppetlabs/code/environments/image
    mkdir -p /etc/puppetlabs/data /etc/puppetlabs/facts
    chgrp -R puppet /etc/puppetlabs/data /etc/puppetlabs/facts
    ln -sf /etc/puppetlabs/data/{user_data,user_data.yaml,terraform_data.yaml} /etc/puppetlabs/code/environments/production/data/
    ln -sf /etc/puppetlabs/facts/terraform_facts.yaml /etc/puppetlabs/code/environments/production/site/profile/facts.d

    # We use r10k solely to install the modules of the production puppet environment.
    /opt/puppetlabs/puppet/bin/r10k puppetfile install --moduledir=/etc/puppetlabs/code/environments/production/modules --puppetfile=/etc/puppetlabs/code/environments/production/Puppetfile
    test -f /etc/puppetlabs/code/Puppetfile && /opt/puppetlabs/puppet/bin/r10k puppetfile install --moduledir=/etc/puppetlabs/code/modules --puppetfile=/etc/puppetlabs/code/Puppetfile
    NEW_ENV=true
fi

# unzip is not necessarily installed when connecting, but python is.
/usr/libexec/platform-python -c "import zipfile; zipfile.ZipFile('${ZIP_FILE}').extractall()"

chmod g-w,o-rwx $(find ${ZIP_DIR}/ -type f ! -path ${ZIP_DIR}/code/*)
chown -R root:52 ${ZIP_DIR}
mkdir -p -m 755 /etc/puppetlabs/
rsync -avh --no-t --exclude 'data' ${ZIP_DIR}/ /etc/puppetlabs/
rsync -avh --no-t --del ${ZIP_DIR}/data/ /etc/puppetlabs/data/
rm -rf ${ZIP_DIR}/

if [ -f /opt/puppetlabs/puppet/bin/r10k ] && [ /etc/puppetlabs/code/Puppetfile -nt /etc/puppetlabs/code/modules ]; then
    /opt/puppetlabs/puppet/bin/r10k puppetfile install --moduledir=/etc/puppetlabs/code/modules --puppetfile=/etc/puppetlabs/code/Puppetfile
    touch /etc/puppetlabs/code/modules
fi

if [[ "${NEW_ENV}" == "true" ]]; then
    cd /etc/puppetlabs/code/environments/production; test -e bootstrap.sh && ./bootstrap.sh
    touch /etc/puppetlabs/code/environments/production/.bootstrapped
fi

if [ -f /usr/local/bin/consul ] && [ -f /usr/bin/jq ]; then
    /usr/local/bin/consul event -token=$(jq -r .acl.tokens.agent /etc/consul/config.json) -name=puppet $(date +%s)
fi