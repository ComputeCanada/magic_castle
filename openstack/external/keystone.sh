#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -x "$(command -v "python3")" ]; then
    python3 ${SCRIPT_DIR}/keystone.py
elif [ -x "$(command -v "python")" ]; then
    python ${SCRIPT_DIR}/keystone.py
else
    echo "Could not find Python in PATH"
    exit 1
fi