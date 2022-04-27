#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -x "$(command -v "python3")" ]; then
    python3 ${SCRIPT_DIR}/keystone.py
elif [ -x "$(command -v "python2")" ]; then
    python2 ${SCRIPT_DIR}/keystone.py
elif [ -x "$(command -v "python")" ]; then
    python ${SCRIPT_DIR}/keystone.py
else
    # Python could not be found that's... unfortunate
    # We will have to do the job in shell script instead, ugh!
    local s="${AUTH_URL/#*:\/\/}"
    name="${s%%.*}"
    echo "{ \"auth_url\" : \"${OS_AUTH_URL}\" , \"name\":  \"${name}\" }"
fi