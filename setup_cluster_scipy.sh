#!/bin/bash

# source configuration
echo "Source configuration in setup_cluster_conf.sh ..."
source setup_cluster_conf.sh || exit $?


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

# Install base packages
$PIP_INSTALL_LOGIN pip || exit $?
$PIP_INSTALL_LOGIN setuptools || exit $?
$PIP_INSTALL_LOGIN readline || exit $?
$PIP_INSTALL_LOGIN nose six pkgconfig setuptools-scm future || exit $?

echo -e "\nInstall pyzmq with --zmq=${ZMQ_PREFIX}"
$PIP_INSTALL_LOGIN --install-option "--zmq=${ZMQ_PREFIX}" pyzmq || exit $?

$PIP_INSTALL_LOGIN git+git://github.com/andsor/gridmap || exit $?

# Download further packages for compilation on cluster
echo -e "\nDownload further packages for compilation on cluster"
$PIP_DOWNLOAD_LOGIN numpy scipy h5py cython || exit $?

# NOW EXECUTE setup_cluster_scipy_cluster.sh on one cluster of your choice
# (default: skadi)
echo "Submit cluster installation and compilation to queue ${BUILD_CLUSTER}..."
_THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
qsub -q ${BUILD_CLUSTER}.q -b yes -S /bin/bash -cwd -j yes -o ${VENV_PREFIX} \
-sync yes ${_THIS_DIR}/setup_cluster_scipy_cluster.sh || exit $?


# Test NumPy on login
echo -e "\nTest NumPy..."
python -c 'import numpy; numpy.show_config()' || exit $?
python -c 'import numpy; numpy.test()' || exit $?

# Test SciPy on login
echo -e "\nTest SciPy..."
python -c 'import scipy; scipy.show_config()' || exit $?
python -c 'import scipy; scipy.test()' || exit $?

# Test h5py on login
echo -e "\nTest h5py..."
python -c 'import h5py; h5py.run_tests()' || exit $?

for CLUSTER in $TEST_CLUSTERS; do
    CLUSTER_LD_LIBRARY_PATH=/usr/nld/atlas-${ATLAS_VERSION}-${CLUSTER}${ATLAS_SUFFIX}/lib:${GCC_LD_LIBRARY_PATH}
    
    # Test GridMap
    echo -e "\nTest GridMap on cluster ${CLUSTER}..."
    python -c "import gridmap; import test_gridmap; \
    print(gridmap.grid_map(test_gridmap.get_environment, [None], \
    name='testgridmap', quiet=False, require_cluster=True, queue='${CLUSTER}.q', \
    temp_dir='${VENV_PREFIX}', local=False, copy_env=False, \
    add_env={'LD_LIBRARY_PATH': '${CLUSTER_LD_LIBRARY_PATH}'}, \
    completion_mail=True))" &

    # Test NumPy on cluster
    echo -e "\nTest NumPy via GridMap on cluster ${CLUSTER}..."
    python -c "import gridmap; import test_gridmap; \
    gridmap.grid_map(test_gridmap.run_numpy_tests, [None], \
    name='testnumpy', quiet=False, require_cluster=True, queue='${CLUSTER}.q', \
    temp_dir='${VENV_PREFIX}', local=False, copy_env=False, \
    add_env={'LD_LIBRARY_PATH': '${CLUSTER_LD_LIBRARY_PATH}'}, \
    completion_mail=True)" &

    # Test SciPy on cluster
    echo -e "\nTest SciPy via GridMap on cluster ${CLUSTER}..."
    python -c "import gridmap; import test_gridmap; \
    gridmap.grid_map(test_gridmap.run_scipy_tests, [None], \
    name='testscipy', quiet=False, require_cluster=True, queue='${CLUSTER}.q', \
    temp_dir='${VENV_PREFIX}', local=False, copy_env=False, \
    add_env={'LD_LIBRARY_PATH': '${CLUSTER_LD_LIBRARY_PATH}'}, \
    completion_mail=True)" &

    # Test h5py on cluster
    echo -e "\nTest h5py via GridMap on cluster ${CLUSTER}..."
    python -c "import gridmap; import test_gridmap; \
    gridmap.grid_map(test_gridmap.run_h5py_tests, [None], \
    name='testh5py', quiet=False, require_cluster=True, queue='${CLUSTER}.q', \
    temp_dir='${VENV_PREFIX}', local=False, copy_env=False, \
    add_env={'LD_LIBRARY_PATH': '${CLUSTER_LD_LIBRARY_PATH}'}, \
    completion_mail=True)" &

done
