#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -x "$(command -v "python3")" ]; then
    cat - | python3 ${SCRIPT_DIR}/machine_type.py
elif [ -x "$(command -v "python2")" ]; then
    cat - | python2 ${SCRIPT_DIR}/machine_type.py
elif [ -x "$(command -v "python")" ]; then
    cat - | python ${SCRIPT_DIR}/machine_type.py
fi
