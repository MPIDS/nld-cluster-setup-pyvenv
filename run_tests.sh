#!/bin/bash

# source configuration
echo "Source configuration in setup_cluster_conf.sh ..."
source setup_cluster_conf.sh || exit $?

# Source virtual environment
echo -e "\nSource virtual environment..."
echo "source ${VENV_ACTIVATE}"
source $VENV_ACTIVATE || exit $?

VENV_NAME=$(basename ${VENV_PREFIX})

echo -e "\nSubmit test jobs to the clusters ${TEST_CLUSTERS}..."
for CLUSTER in $TEST_CLUSTERS; do
    CLUSTER_LD_LIBRARY_PATH=/usr/nld/atlas-${ATLAS_VERSION}-${CLUSTER}${ATLAS_SUFFIX}/lib:${GCC_LD_LIBRARY_PATH}
    
    # Test GridMap
    echo -e "\nTest GridMap on cluster ${CLUSTER}..."
    python -c "import gridmap; import test_gridmap; \
    print(gridmap.grid_map(test_gridmap.get_environment, [None], \
    name='${VENV_NAME}-test-gridmap-${CLUSTER}', queue='${CLUSTER}.q', \
    ${TEST_GRIDMAP_PARAMS},
    add_env={'LD_LIBRARY_PATH': '${CLUSTER_LD_LIBRARY_PATH}'}))" &

    # Test NumPy on cluster
    echo -e "\nTest NumPy via GridMap on cluster ${CLUSTER}..."
    python -c "import gridmap; import test_gridmap; \
    gridmap.grid_map(test_gridmap.run_numpy_tests, [None], \
    name='${VENV_NAME}-test-numpy-${CLUSTER}', queue='${CLUSTER}.q', \
    ${TEST_GRIDMAP_PARAMS},
    add_env={'LD_LIBRARY_PATH': '${CLUSTER_LD_LIBRARY_PATH}'})" &

    # Test SciPy on cluster
    echo -e "\nTest SciPy via GridMap on cluster ${CLUSTER}..."
    python -c "import gridmap; import test_gridmap; \
    gridmap.grid_map(test_gridmap.run_scipy_tests, [None], \
    name='${VENV_NAME}-test-scipy-${CLUSTER}', queue='${CLUSTER}.q', \
    ${TEST_GRIDMAP_PARAMS},
    add_env={'LD_LIBRARY_PATH': '${CLUSTER_LD_LIBRARY_PATH}'})" &

    # Test h5py on cluster
    echo -e "\nTest h5py via GridMap on cluster ${CLUSTER}..."
    python -c "import gridmap; import test_gridmap; \
    gridmap.grid_map(test_gridmap.run_h5py_tests, [None], \
    name='${VENV_NAME}-test-h5py-${CLUSTER}', queue='${CLUSTER}.q', \
    ${TEST_GRIDMAP_PARAMS},
    add_env={'LD_LIBRARY_PATH': '${CLUSTER_LD_LIBRARY_PATH}'})" &

done


# Test NumPy on login
echo -e "\nTest NumPy on this machine..."
python -c 'import numpy; numpy.show_config()' || exit $?
python -c 'import numpy; numpy.test()' || exit $?

# Test SciPy on login
echo -e "\nTest SciPy on this machine..."
python -c 'import scipy; scipy.show_config()' || exit $?
python -c 'import scipy; scipy.test()' || exit $?

# Test h5py on login
echo -e "\nTest h5py on this machine..."
python -c 'import h5py; h5py.run_tests()' || exit $?
