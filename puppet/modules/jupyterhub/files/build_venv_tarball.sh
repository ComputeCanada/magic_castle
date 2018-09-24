#!/bin/bash
VENV="/dev/shm/jupyter"
rm -rf $VENV
mkdir -p $VENV
PYTHON="/cvmfs/soft.computecanada.ca/easybuild/software/2017/Core/python/3.7.0/bin/python3"
$PYTHON -m virtualenv $VENV
source $VENV/bin/activate
pip install --no-cache-dir jupyterhub notebook jupyterlmod nbserverproxy
pip install --no-cache-dir https://github.com/cmd-ntrf/batchspawner/archive/remote_port.zip
pip install --no-cache-dir https://github.com/jupyterhub/nbrsessionproxy/archive/master.zip

jupyter nbextension install --py jupyterlmod --sys-prefix
jupyter nbextension enable --py jupyterlmod --sys-prefix
jupyter serverextension enable --py jupyterlmod --sys-prefix
jupyter serverextension enable --py nbserverproxy --sys-prefix
jupyter nbextension install --py nbrsessionproxy --sys-prefix
jupyter nbextension enable --py nbrsessionproxy --sys-prefix
jupyter serverextension enable --py nbrsessionproxy --sys-prefix

deactivate

# Create deployable environment tarball
$PYTHON -m virtualenv --relocatable $VENV
sed -i 's;VIRTUAL_ENV=.*;VIRTUAL_ENV=$(readlink -f $(dirname $BASH_SOURCE)/..);g' $VENV/bin/activate
tar czf /project/jupyter_singleuser.tar.gz --directory=$VENV/.. jupyter
rm -rf $VENV
