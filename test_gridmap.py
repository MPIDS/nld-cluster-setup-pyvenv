# coding: utf-8

import os


def get_environment(*args, **kwargs):
    return dict(os.environ)


def get_numpy_version(*args, **kwargs):
    import numpy

    return numpy.__version__


def run_numpy_tests(*args, **kwargs):
    import numpy

    numpy.show_config()
    numpy.test()


def run_scipy_tests(*args, **kwargs):
    import scipy

    scipy.show_config()
    scipy.test()


def run_h5py_tests(*args, **kwargs):
    import h5py

    h5py.run_tests()
