#!/bin/bash

# source configuration
source setup_cluster_conf.sh || exit $?

# Source virtual environment
source $VENV_ACTIVATE || exit $?

# Install NumPy
export ATLAS=$ATLAS_PREFIX
$PIP_INSTALL_CLUSTER numpy -v || exit $?
python -c 'import numpy; numpy.show_config()' || exit $?
python -c 'import numpy; numpy.test()' || exit $?

# Install SciPy
$PIP_INSTALL_CLUSTER scipy -v || exit $?
python -c 'import scipy; scipy.show_config()' || exit $?

# Fix SciPy issue https://github.com/scipy/scipy/issues/5197
sed -i '/assert_array_almost_equal_nulp(mstats.kurtosis(.*$/{$!{N;s/\(assert_array_almost_equal_nulp(mstats.kurtosis.*\n[[:blank:]]*\)\(stats.kurtosis(\)/# \1# \2/}}' $VENV_PREFIX/lib/python3.4/site-packages/scipy/stats/tests/test_mstats_basic.py
python -c 'import scipy; scipy.test()' || exit $?

# Install h5py
export HDF5_DIR=$HDF_PREFIX
$PIP_INSTALL_CLUSTER h5py -v || exit $?
python -c 'import h5py; h5py.run_tests()' || exit $?
