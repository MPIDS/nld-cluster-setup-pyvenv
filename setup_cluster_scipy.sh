#!/bin/bash

# source configuration
echo "Source configuration in setup_cluster_conf.sh ..."
source setup_cluster_conf.sh || exit $?

# source Queueing system settings
if [[ ${SGE_CLUSTER_NAME} = NLD ]]; then
    echo -e "\nQueueing system settings already sourced."
else
    echo -e "\nSourcing queueing system settings..."
    source $QUEUEING_SETTINGS || exit $?
fi

# Create Python virtual environment
echo -e "\nCreate Python virtual environment..."
echo "${PYTHON_PREFIX}/bin/pyvenv ${VENV_PREFIX}"
$PYTHON_PREFIX/bin/pyvenv $VENV_PREFIX || exit $?

# Modify virtual environment
echo -e "\nModify virtual environment in ${VENV_ACTIVATE}..."
cp $VENV_ACTIVATE $VENV_ACTIVATE.backup
echo "" >> $VENV_ACTIVATE
echo "# Manual additions" >> $VENV_ACTIVATE
echo 'CLUSTERNAME=`hostname | grep -o "[[:alpha:]]*"`' >> $VENV_ACTIVATE
echo "" >> $VENV_ACTIVATE
echo "# C Compiler" >> $VENV_ACTIVATE
echo "export CC=${GCC_CC}" >> $VENV_ACTIVATE
echo "export PATH=${GCC_PATH}"':${PATH}' >> $VENV_ACTIVATE
echo "export LD_LIBRARY_PATH=${GCC_LD_LIBRARY_PATH}"':${LD_LIBRARY_PATH}' >> $VENV_ACTIVATE
echo "" >> $VENV_ACTIVATE
echo "# ATLAS" >> $VENV_ACTIVATE
echo "ATLAS_CLUSTER=${ATLAS_CLUSTER_EXPRESSION}" >> $VENV_ACTIVATE
echo 'ATLAS_PREFIX=/usr/nld/atlas-'$ATLAS_VERSION'-${ATLAS_CLUSTER}'$ATLAS_SUFFIX >> $VENV_ACTIVATE
echo 'export LD_LIBRARY_PATH=${ATLAS_PREFIX}/lib:${LD_LIBRARY_PATH}' >> $VENV_ACTIVATE
echo "" >> $VENV_ACTIVATE
echo "# Queueing system settings" >> $VENV_ACTIVATE
echo '[[ ${CLUSTERNAME} = login ]] && [[ ${SGE_CLUSTER_NAME} != NLD ]] && source '${QUEUEING_SETTINGS} >> $VENV_ACTIVATE
echo "" >> $VENV_ACTIVATE
echo "# DRMAA" >> $VENV_ACTIVATE
echo "export DRMAA_LIBRARY_PATH=${_DRMAA_LIBRARY_PATH}" >> $VENV_ACTIVATE
echo "" >> $VENV_ACTIVATE
echo "# GridMap" >> $VENV_ACTIVATE
echo 'export SMTP_SERVER=mailer.nld.ds.mpg.de' >> $VENV_ACTIVATE
echo 'export CREATE_PLOTS=False' >> $VENV_ACTIVATE
echo 'export ERROR_MAIL_SENDER=$USER@nld.ds.mpg.de' >> $VENV_ACTIVATE
echo 'export ERROR_MAIL_RECIPIENT=$USER@nld.ds.mpg.de' >> $VENV_ACTIVATE
diff $VENV_ACTIVATE.backup $VENV_ACTIVATE


# Source virtual environment
echo -e "\nSource virtual environment..."
echo "source ${VENV_ACTIVATE}"
source $VENV_ACTIVATE || exit $?

mkdir -p $PIP_CACHE || exit $?

# Install base packages
$PIP_UPGRADE_PIP_LOGIN 'pip>=9' || exit $?
$PIP_INSTALL_LOGIN setuptools || exit $?
$PIP_INSTALL_LOGIN wheel || exit $?

$PIP_WHEEL_LOGIN_GENERAL readline || exit $?
$PIP_INSTALL_LOGIN_GENERAL readline || exit $?
$PIP_WHEEL_LOGIN_GENERAL nose six pkgconfig setuptools-scm future || exit $?
$PIP_INSTALL_LOGIN_GENERAL nose six pkgconfig setuptools-scm future || exit $?

echo -e "\nInstall pyzmq with --zmq=${ZMQ_PREFIX}"
$PIP_WHEEL_LOGIN_ZMQ --build-option "--zmq=${ZMQ_PREFIX}" pyzmq || exit $?
$PIP_INSTALL_LOGIN_ZMQ pyzmq || exit $?

$PIP_WHEEL_LOGIN_GENERAL git+git://github.com/pygridtools/gridmap || exit $?
$PIP_INSTALL_LOGIN_GENERAL gridmap || exit $?

# Download further packages for compilation on cluster
echo -e "\nDownload further packages for compilation on cluster"
$PIP_DOWNLOAD_LOGIN numpy 'scipy>=0.18' h5py cython || exit $?

# NOW EXECUTE setup_cluster_scipy_cluster.sh on one cluster of your choice
# (default: skadi)
echo "Submit cluster installation and compilation to queue ${BUILD_CLUSTER}..."
_THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
qsub -q ${BUILD_CLUSTER}.q -b yes -S /bin/bash -cwd -j yes -o ${VENV_PREFIX} \
-sync yes ${_THIS_DIR}/setup_cluster_scipy_cluster.sh || exit $?

# Run tests
./run_tests.sh || exit $?
