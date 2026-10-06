#!/bin/bash
ZIP_FILE="/tmp/etc_puppetlabs.zip"
GIT_URL="${1}"
GIT_REF="${2}"
ORIGIN="${3}"

set -e

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
if [ ! -e "${PUPPET_ENV}" ]; then
    TEMP_ENV_DIR=$(mktemp -d)
    chown root:puppet $TEMP_ENV_DIR
    chmod 0750 $TEMP_ENV_DIR
    /usr/bin/go-getter git::${GIT_URL}?ref=${GIT_REF} ${TEMP_ENV_DIR}
    ln -sf /etc/puppetlabs/data/{user_data,user_data.yaml,terraform_data.yaml} ${TEMP_ENV_DIR}/data/
    ln -sf /etc/puppetlabs/puppet/data/credentials.yaml ${TEMP_ENV_DIR}/data/
    ln -sf /etc/puppetlabs/facts/terraform_facts.yaml ${TEMP_ENV_DIR}/site/profile/facts.d
    /opt/puppetlabs/puppet/bin/r10k puppetfile install --moduledir=${TEMP_ENV_DIR}/modules --puppetfile=${TEMP_ENV_DIR}/Puppetfile
    mv ${TEMP_ENV_DIR} ${PUPPET_ENV}
    NEW_PUPPET_ENV="true"
fi

if [ ! "$(readlink "/etc/puppetlabs/code/environments/production")" = "$PUPPET_ENV" ]; then
    ln -snf ${PUPPET_ENV} /etc/puppetlabs/code/environments/production
    ln -snf ${PUPPET_ENV} /etc/puppetlabs/code/environments/image
fi

if [ ! -e /etc/puppetlabs/puppet/data/credentials.yaml ]; then
    ${PUPPET_ENV}/generate_credentials.sh
fi

if [[ "${NEW_PUPPET_ENV}" == "true" ]]; then
    /opt/puppetlabs/puppet/bin/puppet apply /etc/puppetlabs/code/environments/production/manifests/site.pp  --tags mc_bootstrap
fi

if [ -f /usr/local/bin/consul ] && [ -f /usr/bin/jq ]; then
    /usr/local/bin/consul event -token=$(jq -r .acl.tokens.agent /etc/consul/config.json) -name=puppet $(date +%s)
fi