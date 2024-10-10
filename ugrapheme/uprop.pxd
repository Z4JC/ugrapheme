#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD

from cpython.object cimport PyObject


cdef extern from *:
    """
    # include <Python.h>

    static inline PyObject *PyUnicode_New_by_Uprop(Py_ssize_t size,
                                                   int uprop) {
        static Py_UCS4 maxchar_by_uprop[] = { 0, 0, 0xFFFF, 0, 0x10FFFF };
        return PyUnicode_New(size, maxchar_by_uprop[uprop >> 8]
                                   | (uprop & 0xFF));
    }

    static int kind_from_uprop(int uprop) {
        return uprop >> 8;
    }

    static int uprop_from_unicode(PyObject *obj) {
        return (PyUnicode_KIND(obj) << 8)
               | (0xFF - (-PyUnicode_IS_ASCII(obj) & 0x80));
    }

    #define Uprop_ASCII  0x17f
    #define Uprop_Latin1 0x1ff
    #define Uprop_2BYTE  0x2ff
    #define Uprop_4BYTE  0x4ff
    """
    unicode PyUnicode_New_by_Uprop(Py_ssize_t size, int uprop)
    PyObject *_PyUnicode_New_by_Uprop "PyUnicode_New_by_Uprop" (Py_ssize_t size,
                                                                int uprop)
    int kind_from_uprop(int uprop)
    int uprop_from_unicode(unicode obj)
    int _uprop_from_unicode "uprop_from_unicode" (PyObject *obj)
    int Uprop_ASCII
    int Uprop_Latin1
    int Uprop_2BYTE
    int Uprop_4BYTE
