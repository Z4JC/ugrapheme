#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD/

from cpython.object cimport PyObject


cdef extern from *:
    """
    # include <Python.h>
    """
    int _PyUnicode_Check "PyUnicode_Check" (PyObject *ob) noexcept
    void *_PyUnicode_DATA "PyUnicode_DATA" (PyObject *ob) noexcept
    Py_ssize_t _PyUnicode_GET_LENGTH "PyUnicode_GET_LENGTH" (
        PyObject *ob) noexcept
    unsigned int _PyUnicode_KIND "PyUnicode_KIND" (PyObject *ob) noexcept
    int PyUnicode_Resize(PyObject **p_unicode, Py_ssize_t length)
