# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
import ctypes
from ugrapheme import graphemes


class PyASCIIObject(ctypes.Structure):
    _fields_ = [
        ("ob_refcnt", ctypes.c_long),
        ("ob_type", ctypes.c_void_p),
        ("length", ctypes.c_ssize_t),
        ("hash", ctypes.c_ssize_t),
        ("interned", ctypes.c_uint, 2),
        ("kind", ctypes.c_uint, 3),
        ("compact", ctypes.c_uint, 1),
        ("ascii", ctypes.c_uint, 1),
    ]

    def __repr__(self):
        return '<PyASCIIObject: kind=%d, ascii=%d>' % (self.kind, self.ascii)

    __str__ = __repr__


def str_diag(s):
    if isinstance(s, graphemes):
        s = str(s)
    if not isinstance(s, str):
        raise TypeError("Expected an str or graphemes, got '%s'"
                        % type(s).__name__)
    return PyASCIIObject.from_address(id(s))


def is_ascii(s):
    o = str_diag(s)
    return bool(o.ascii)


def is_latin1(s):
    o = str_diag(s)
    return not bool(o.ascii) and o.kind == 1


def is_2byte_unicode(s):
    o = str_diag(s)
    return not bool(o.ascii) and o.kind == 2


def is_4byte_unicode(s):
    o = str_diag(s)
    return not bool(o.ascii) and o.kind == 4
