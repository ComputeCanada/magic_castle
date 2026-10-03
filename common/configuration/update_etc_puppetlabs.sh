#!/bin/bash
ZIP_FILE="/tmp/etc_puppetlabs.zip"
GIT_URL="${1}"
GIT_REF="${2}"
ORIGIN="${3}"

if [[ "${ORIGIN}" == "tf" ]] && [[ $(cloud-init status) != "status: done" ]]; then
    exit
fi

TEMP_DIR=$(mktemp -d)
EXTRACT_DIR="${TEMP_DIR}/$(basename ${ZIP_FILE%.zip})"
unzip ${ZIP_FILE} -d ${TEMP_DIR}

chmod g-w,o-rwx $(find ${EXTRACT_DIR} -type f ! -path ${EXTRACT_DIR}/code/*)
chown -R root:puppet ${EXTRACT_DIR}
rsync -avh --no-t --exclude 'data' ${EXTRACT_DIR}/ /etc/puppetlabs/
rsync -avh --no-t --del ${EXTRACT_DIR}/data/ /etc/puppetlabs/data/

rm -rf ${TEMP_DIR} ${ZIP_FILE}

if [ /etc/puppetlabs/code/Puppetfile -nt /etc/puppetlabs/code/modules ]; then
    /opt/puppetlabs/puppet/bin/r10k puppetfile install --moduledir=/etc/puppetlabs/code/modules --puppetfile=/etc/puppetlabs/code/Puppetfile
    touch /etc/puppetlabs/code/modules
fi

PUPPET_ENV="/etc/puppetlabs/code/environments/${GIT_REF}"
ln -snf ${PUPPET_ENV} /etc/puppetlabs/code/environments/production
ln -snf ${PUPPET_ENV} /etc/puppetlabs/code/environments/image
if [ ! -e "${PUPPET_ENV}" ]; then
    /usr/bin/go-getter git::${GIT_URL}?ref=${GIT_REF} ${PUPPET_ENV}
    ln -sf /etc/puppetlabs/data/{user_data,user_data.yaml,terraform_data.yaml} ${PUPPET_ENV}/data/
    ln -sf /etc/puppetlabs/facts/terraform_facts.yaml ${PUPPET_ENV}/site/profile/facts.d
    /opt/puppetlabs/puppet/bin/r10k puppetfile install --moduledir=${PUPPET_ENV}/modules --puppetfile=${PUPPET_ENV}/Puppetfile
    test -e ${PUPPET_ENV}/bootstrap.sh && ${PUPPET_ENV}/bootstrap.sh
fi

if [ -f /usr/local/bin/consul ] && [ -f /usr/bin/jq ]; then
    /usr/local/bin/consul event -token=$(jq -r .acl.tokens.agent /etc/consul/config.json) -name=puppet $(date +%s)
fi