#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
from cpython cimport array

cpdef array.array array_uint8(size_t sz, zero=*)
cpdef array.array array_uint16(size_t sz, zero=*)
cpdef array.array array_uint32(size_t sz, zero=*)
cpdef array.array array_int8(size_t sz, zero=*)
cpdef array.array array_int16(size_t sz, zero=*)
cpdef array.array array_int32(size_t sz, zero=*)
