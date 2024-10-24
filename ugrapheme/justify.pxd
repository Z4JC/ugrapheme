#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD

cpdef unicode ljust(unicode ustr, Py_ssize_t width, unicode fillchar=*,
                    wcwidth=*)
cpdef unicode rjust(unicode ustr, Py_ssize_t width, unicode fillchar=*,
                    wcwidth=*)
cpdef unicode center(unicode ustr, Py_ssize_t width, unicode fillchar=*,
                     wcwidth=*)
