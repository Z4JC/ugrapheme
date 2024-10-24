#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
from cpython.unicode cimport (PyUnicode_GetLength, PyUnicode_KIND,
                              PyUnicode_DATA, PyUnicode_1BYTE_DATA,
                              PyUnicode_1BYTE_KIND, PyUnicode_2BYTE_KIND,
                              PyUnicode_4BYTE_KIND,
                              PyUnicode_FromKindAndData)
from libc.stdint cimport uint8_t, uint16_t, uint32_t

from ugrapheme.latin1 cimport init_latin1, get_latin1
from ugrapheme.ugrapheme cimport grapheme_split_uint32


init_latin1()


cdef class grapheme_byte_iter:
    cdef unicode ustr
    cdef uint8_t *data
    cdef size_t i, l

    def __cinit__(self):
        self.i = 1
        self.l = 0

    def __iter__(self):
        return self

    def __next__(self):
        cdef size_t last_i = self.i, i = last_i + 1, l = self.l
        cdef uint8_t *data8 = self.data
        if i < l:
            if data8[i - 1] == 0x0d and data8[i] == 0x0a:
                self.i = i + 1
                return '\u000d\u000a'
            self.i = i
            return get_latin1(data8[i - 1])
        elif i == l:
            last_i = self.i
            self.i = i
            return (get_latin1(data8[last_i]) if l - last_i == 1
                    else '\u000d\u000a')
        else:
            raise StopIteration


cdef inline grapheme_byte_iter make_grapheme_byte_iter(unicode ustr,
                                                       size_t pos,
                                                       size_t l):
    cdef grapheme_byte_iter it = grapheme_byte_iter()
    it.ustr = ustr
    it.data = <uint8_t *> PyUnicode_DATA(ustr)
    it.i = pos
    it.l = l
    return it


cdef class grapheme_2byte_iter:
    cdef unicode ustr
    cdef uint16_t *data
    cdef size_t i, l
    cdef uint16_t tran

    def __cinit__(self):
        self.i = 1
        self.l = 0

    def __iter__(self):
        return self

    def __next__(self):
        cdef size_t last_i = self.i, i = last_i + 1, l = self.l
        cdef uint16_t tran = self.tran
        cdef uint16_t *data16 = self.data
        while i < l:
            tran = grapheme_split_uint32(tran, data16[i - 1], data16[i])
            if tran & 0x100 == 0:
                i += 1
                continue
            self.tran = tran
            self.i = i
            return PyUnicode_FromKindAndData(PyUnicode_2BYTE_KIND,
                                             &data16[last_i], i - last_i)
        if i == l:
            last_i = self.i
            self.i = i
            return PyUnicode_FromKindAndData(PyUnicode_2BYTE_KIND,
                                             &data16[last_i], l - last_i)
        else:
            raise StopIteration


cdef inline grapheme_2byte_iter make_grapheme_2byte_iter(unicode ustr,
                                                        size_t pos,
                                                        size_t l):
    cdef grapheme_2byte_iter it = grapheme_2byte_iter()
    it.ustr = ustr
    it.data = <uint16_t *> PyUnicode_DATA(ustr)
    it.i = pos
    it.l = l
    return it


cdef class grapheme_4byte_iter:
    cdef unicode ustr
    cdef uint32_t *data
    cdef size_t i, l
    cdef uint16_t tran

    def __cinit__(self):
        self.i = 1
        self.l = 0

    def __iter__(self):
        return self

    def __next__(self):
        cdef size_t last_i = self.i, i = last_i + 1, l = self.l
        cdef uint16_t tran = self.tran
        cdef uint32_t *data32 = self.data
        while i < l:
            tran = grapheme_split_uint32(tran, data32[i - 1], data32[i])
            if tran & 0x100 == 0:
                i += 1
                continue
            self.tran = tran
            self.i = i
            return PyUnicode_FromKindAndData(PyUnicode_4BYTE_KIND,
                                             &data32[last_i], i - last_i)
        if i == l:
            last_i = self.i
            self.i = i
            return PyUnicode_FromKindAndData(PyUnicode_4BYTE_KIND,
                                             &data32[last_i], l - last_i)
        else:
            raise StopIteration


cdef inline grapheme_4byte_iter make_grapheme_4byte_iter(unicode ustr,
                                                         size_t pos,
                                                         size_t l):
    cdef grapheme_4byte_iter it = grapheme_4byte_iter()
    it.ustr = ustr
    it.data = <uint32_t *> PyUnicode_DATA(ustr)
    it.i = pos
    it.l = l
    return it


cpdef object grapheme_iter(unicode ustr):
    """Returns an iterator over the graphemes in string str.

    Returns an iterator where each returned element is a string representing
    a grapheme.

    Example:
        print(','.join(grapheme_iter('👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi')))
      prints: 👩🏽‍🔬,🏴󠁧󠁢󠁳󠁣󠁴󠁿,H,i

    Compare that to doing print(','.join('👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi')) which will produce
    garbled output because the scientist and the flag graphemes are represented
    using a total of 11 unicode codepoints/characters, with python inserting
    commas in between each one of those characters."""
    cdef size_t l = PyUnicode_GetLength(ustr)
    if l == 0:
        return grapheme_empty_iter()

    cdef unsigned int kind = PyUnicode_KIND(ustr)

    if kind == PyUnicode_1BYTE_KIND:
        return make_grapheme_byte_iter(ustr, 0, l)
    elif kind == PyUnicode_2BYTE_KIND:
        return make_grapheme_2byte_iter(ustr, 0, l)
    elif kind == PyUnicode_4BYTE_KIND:
        return make_grapheme_4byte_iter(ustr, 0, l)


cdef class grapheme_empty_iter:
    def __iter__(self):
        return self

    def __next__(self):
        raise StopIteration
