#!/bin/bash

ZIP_FILE=${1}
ZIP_DIR=${ZIP_FILE%.zip}

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

if [ -f /usr/local/bin/consul ] && [ -f /usr/bin/jq ]; then
    /usr/local/bin/consul event -token=$(jq -r .acl.tokens.agent /etc/consul/config.json) -name=puppet $(date +%s)
fi
