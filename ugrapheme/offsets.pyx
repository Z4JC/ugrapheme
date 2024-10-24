#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD

from cpython cimport array
from cpython.unicode cimport (PyUnicode_GetLength, PyUnicode_KIND,
                              PyUnicode_DATA,
                              PyUnicode_1BYTE_KIND, PyUnicode_2BYTE_KIND,
                              PyUnicode_4BYTE_KIND)

from libc.stdint cimport uint8_t, uint16_t, uint32_t
from ugrapheme.alloc cimport array_uint32
from ugrapheme.ugrapheme cimport grapheme_split_uint32, rule_brk_below_0x300


cpdef array.array grapheme_offsets(unicode ustr):
    """Returns an array of offsets into grapheme characters.

    A graphemes string consists of grapheme characters which correspond
    to one or more unicode codepoints in the underlying string.
    Returns an array of 32-bit unsigned ints where the i-th element
    is index of the i-th grapheme in the unicode string ustr.

    Example: list(grapheme_offsets('Hi\\u000d\\u000athere'))
                returns [0, 1, 2, 4, 5, 6, 7, 8, 9]

    The grapheme 'H' begins at index 0 in the string 'Hi\\u000d\\u000athere'
    The grapheme 'i' begins at index 1 in the string
    The grapheme CRLF begins at index 2 in the string
    The grapheme 't' begins at index 4 in the string
     ...and so on
    The last offset returned corresponds to the total number of unicode
    codepoints needed to represent the underlying python string."""
    cdef size_t l = PyUnicode_GetLength(ustr)
    if l == 0:
        return array_uint32(0)

    cdef array.array arr = array_uint32(l + 1)

    cdef size_t new_l = _grapheme_offsets(ustr, l,
                                          <uint32_t *> arr.data.as_voidptr,
                                          0, 0)
    array.resize(arr, new_l)
    return arr


cdef uint32_t _grapheme_offsets(unicode ustr, size_t l,
                                uint32_t *out, uint32_t initial,
                                uint32_t upos) noexcept:
    if l == 0:
        return 0

    cdef unsigned int kind = PyUnicode_KIND(ustr)
    if kind == PyUnicode_1BYTE_KIND:
        return _grapheme_offsets_uXX(<uint8_t *> PyUnicode_DATA(ustr), l,
                                     out, initial, upos)
    elif kind == PyUnicode_2BYTE_KIND:
        return _grapheme_offsets_uXX(<uint16_t *> PyUnicode_DATA(ustr), l,
                                     out, initial, upos)
    elif kind == PyUnicode_4BYTE_KIND:
        return _grapheme_offsets_uXX(<uint32_t *> PyUnicode_DATA(ustr), l,
                                     out, initial, upos)


cdef uint32_t _grapheme_offsets_1byte_recalc(uint8_t *ch8_ustr, size_t l,
                                             uint32_t *out, uint32_t initial,
                                             uint32_t upos) noexcept:
    return _grapheme_offsets_uXX_recalc(ch8_ustr, l, out, initial, upos)


cdef uint32_t _grapheme_offsets_2byte_recalc(uint16_t *ch16_ustr, size_t l,
                                             uint32_t *out, uint32_t initial,
                                             uint32_t upos) noexcept:
    return _grapheme_offsets_uXX_recalc(ch16_ustr, l, out, initial, upos)


cdef uint32_t _grapheme_offsets_4byte_recalc(uint32_t *ch32_ustr, size_t l,
                                             uint32_t *out, uint32_t initial,
                                             uint32_t upos) noexcept:
    return _grapheme_offsets_uXX_recalc(ch32_ustr, l, out, initial, upos)


ctypedef fused uintXX_t:
    uint8_t
    uint16_t
    uint32_t


cdef inline uint32_t _grapheme_offsets_uXX(uintXX_t *data, size_t l,
                                           uint32_t *out,
                                           uint32_t initial,
                                           uint32_t upos) noexcept:
    cdef uint16_t tran = 0
    cdef size_t i = 0, count = 1

    out[0] = 0 + initial
    for i in range(1, l):
        if uintXX_t is uint8_t:
            tran = rule_brk_below_0x300(data[upos + i - 1], data[upos + i])
        else:
            tran = grapheme_split_uint32(tran,
                                         data[upos + i - 1], data[upos + i])
        if tran & 0x100 != 0:
            out[count] = i + initial
            count += 1
    out[count] = l + initial
    return count + 1


cdef inline uint32_t _grapheme_offsets_uXX_recalc(uintXX_t *data, size_t l,
                                                  uint32_t *out,
                                                  uint32_t initial,
                                                  uint32_t upos) noexcept:
    cdef uint16_t tran = 0
    cdef size_t i = 0, count = 1

    for i in range(1, l):
        if uintXX_t is uint8_t:
            tran = rule_brk_below_0x300(data[upos + i - 1], data[upos + i])
        else:
            tran = grapheme_split_uint32(tran,
                                         data[upos + i - 1], data[upos + i])
        if tran & 0x100 != 0:
            out[count] = i + initial
            count += 1
    return count
