#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD

from cpython cimport array

import array
from struct import calcsize


if calcsize('I') == 4:
    fmt_int32 = 'i'
    fmt_uint32 = 'I'
elif calcsize('L') == 4:
    fmt_int32 = 'l'
    fmt_uint32 = 'L'
else:
    raise TypeError("What's the 32-bit int type?")


if calcsize('L') == 8:
    fmt_int64 = 'l'
    fmt_uint64 = 'L'
elif calcsize('Q') == 8:
    fmt_int64 = 'q'
    fmt_uint64 = 'Q'
else:
    raise TypeError("What's the 64-bit int type?")


arr_uint8  = array.array('B')
arr_uint16 = array.array('H')

arr_uint32 = array.array(fmt_uint32)
arr_uint64 = array.array(fmt_uint64)

arr_int8  = array.array('b')
arr_int16 = array.array('h')
arr_int32 = array.array(fmt_int32)
arr_int64 = array.array(fmt_int64)


cpdef array.array array_uint8(size_t sz, zero=False):
    return array.clone(arr_uint8, sz, zero=zero)


cpdef array.array array_uint16(size_t sz, zero=False):
    return array.clone(arr_uint16, sz, zero=zero)


cpdef array.array array_uint32(size_t sz, zero=False):
    return array.clone(arr_uint32, sz, zero=zero)


cpdef array.array array_int8(size_t sz, zero=False):
    return array.clone(arr_int8, sz, zero=zero)


cpdef array.array array_int16(size_t sz, zero=False):
    return array.clone(arr_int16, sz, zero=zero)


cpdef array.array array_int32(size_t sz, zero=False):
    return array.clone(arr_int32, sz, zero=zero)
