# nld-cluster-setup-pyvenv
Bash scripts to bootstrap a new Python 3 virtual environment with NumPy, SciPy and GridMap pre-installed

# Acknowledgements

- H.W.G. for sorting out the whole Python, NumPy/SciPy and ATLAS compilation process.
- Debsankha Manik for the wheels blueprint.

# Usage

- ```$ cp setup_cluster_conf.sh.orig setup_cluster_conf.sh```
  
- Adjust ``setup_cluster_conf.sh`` according to your needs.

- ```$ ./setup_cluster_scipy.sh```

# Features

The script creates one virtual environment that fits all clusters.
The machine-dependent ATLAS libraries are linked in via ``$LD_LIBRARY_PATH``.

- Creates a new Python 3 virtual environment in ``$VENV_PREFIX``
- Uses specified GCC
- Updates ``pip`` and ``setuptools``, installs ``readline``
- Compiles ``pyzmq`` (for ``GridMap`` and ``Jupyter``/``IPython``)
- Compiles ``numpy`` and ``scipy`` and links towards cluster-specific ATLAS in ``/usr/nld/atlas-${ATLAS_VERSION}-${CLUSTER}${ATLAS_SUFFIX}``
- Compiles ``h5py``
- Scripts all the necessary environment variables into the ``$VENV_ACTIVATE`` script.
- Builds and caches wheels. Wheels are built per package version, CLUSTER, GCC, and optionally ATLAS, HDF, or ZMQ. If any of these change, a new wheel is automatically built.
