#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -x "$(command -v "python3")" ]; then
    python3 ${SCRIPT_DIR}/key2fp.py
elif [ -x "$(command -v "python2")" ]; then
    python2 ${SCRIPT_DIR}/key2fp.py
elif [ -x "$(command -v "python")" ]; then
    python ${SCRIPT_DIR}/key2fp.py
else
    echo "Could not find Python in PATH"
    exit 1
fi
