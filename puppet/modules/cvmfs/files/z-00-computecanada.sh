if [[ $UID -gt 10000 ]]; then
    if [[ -r /cvmfs/soft.computecanada.ca/config/profile/bash.sh ]]; then
        source /cvmfs/soft.computecanada.ca/config/profile/bash.sh
    fi
fi