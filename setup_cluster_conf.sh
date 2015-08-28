#!/bin/bash

# CONFIGURATION

# GCC
GCC_PREFIX=/usr/nld/gcc-4.7.2
MPC_PREFIX=/usr/nld/mpc-1.0.1
MPFR_PREFIX=/usr/nld/mpfr-3.1.1
GMP_PREFIX=/usr/nld/gmp-5.0.5

# Python
PYTHON_PREFIX=/usr/nld/python-3.4.3b-cluster

# virtual environment
VENV_PREFIX=${HOME}/venvs/scipy
PIP_INSTALL_LOGIN_OPTIONS="--trusted-host pypi.python.org"

# ATLAS
ATLAS_VERSION=3.8.4
ATLAS_SUFFIX=-seq

# HDF5
HDF_PREFIX=/usr/nld/hdf5-1.8.9

# ZeroMQ
ZMQ_PREFIX=/usr/nld/zeromq-4.0.4-skadi

# DRMAA
_DRMAA_LIBRARY_PATH=/core/ge/lib/linux-x64/libdrmaa.so

# Run tests on which cluster?
TEST_CLUSTER=skadi


# DO NOT CHANGE AFTER HERE

VENV_ACTIVATE=${VENV_PREFIX}/bin/activate

# Get cluster name
CLUSTERNAME=`hostname | grep -o "[[:alpha:]]*"`

# C Compiler
GCC_CC=${GCC_PREFIX}/bin/gcc
GCC_PATH=${GCC_PREFIX}/bin
GCC_LD_LIBRARY_PATH=${GCC_PREFIX}/lib64:${MPC_PREFIX}/lib:${MPFR_PREFIX}/lib:${GMP_PREFIX}/lib

# ATLAS
ATLAS_CLUSTER_EXPRESSION='$([ $CLUSTERNAME = login ] && echo "skadi" || echo $CLUSTERNAME)'
ATLAS_CLUSTER=$(eval echo $ATLAS_CLUSTER_EXPRESSION)
ATLAS_PREFIX=/usr/nld/atlas-${ATLAS_VERSION}-${ATLAS_CLUSTER}${ATLAS_SUFFIX}

# pip
PIP_INSTALL_LOGIN="pip install ${PIP_INSTALL_LOGIN_OPTIONS} --upgrade"
PIP_DOWNLOAD_LOGIN="${PIP_INSTALL_LOGIN} --download ${VENV_PREFIX}"
PIP_INSTALL_CLUSTER="pip install --no-index --find-links ${VENV_PREFIX} --upgrade"
