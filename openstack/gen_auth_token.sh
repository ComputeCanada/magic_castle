#!/bin/sh
# Verify if there is a token in the Terraform state

token=$(jq -r '.modules[0]
               .resources["data.external.openstack_token"]
               .primary
               .attributes["result.token"]' terraform.tfstate 2> /dev/null)

# Ask keystone for a token if none was previously set.
if [ "$token" == "" ] || [ "$token" == "null" ]; then
    token=$(
        curl -s -H "Content-Type: application/json"   -d '
        { "auth": {
            "tenantName": "'$OS_TENANT_NAME'",
            "passwordCredentials": {
                "username": "'$OS_USERNAME'",
                "password": "'$OS_PASSWORD'"
            }
            }
        }'   "$OS_AUTH_URL/tokens" | jq -r ".access.token.id"
    )
fi
echo '{"token" : "'$token'"}'