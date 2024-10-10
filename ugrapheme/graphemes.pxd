#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
from cpython.object cimport PyObject
from libc.stdint cimport uint8_t, uint16_t, uint32_t, UINT32_MAX


cdef class graphemes_offsets_iter


cdef public class graphemes [type graphemes_type, object graphemes_obj]:
    cdef unicode ustr
    cdef uint32_t gl, sl
    cdef uint32_t *off

    @staticmethod
    cdef graphemes from_str(unicode ustr)

    @staticmethod
    cdef graphemes empty()

    cpdef graphemes_offsets_iter offsets_iter(self)
    cdef uint32_t length(self)
    cpdef unicode at(self, Py_ssize_t pos)
    cdef unicode at_unsafe(self, Py_ssize_t pos)
    cpdef uint32_t off_at(self, Py_ssize_t pos) except 0xffffffff
    cpdef uint32_t off_to_pos(self, Py_ssize_t off) except 0xffffffff
    cpdef graphemes gslice(self, Py_ssize_t start=*, Py_ssize_t end=*,
                           Py_ssize_t step=*)
    cdef unicode slice(self, Py_ssize_t start, Py_ssize_t end)
    cdef unicode slice_unsafe(self, uint32_t start, uint32_t end)
    cdef unicode slice_stepped(self, Py_ssize_t start, Py_ssize_t end,
                               Py_ssize_t step)
    cpdef graphemes append_str(self, unicode x)
    cpdef graphemes append_graphemes(self, graphemes x)
    cpdef bint has(self, object x, bint partial=*) except 127

    cpdef Py_ssize_t count(self, object sub,
                          Py_ssize_t start=*, Py_ssize_t end=*,
                          bint partial=*) except -1
    cpdef bint endswith(self, object suffix,
                        Py_ssize_t start=*, Py_ssize_t end=*,
                        bint partial=*) except 127
    cpdef bint startswith(self, object suffix,
                          Py_ssize_t start=*, Py_ssize_t end=*,
                          bint partial=*) except 127
    cpdef Py_ssize_t find(self, object sub,
                          Py_ssize_t start=*, Py_ssize_t end=*,
                          bint partial=*) except -2
    cpdef Py_ssize_t rfind(self, object sub,
                           Py_ssize_t start=*, Py_ssize_t end=*,
                           bint partial=*) except -2
    cpdef Py_ssize_t index(self, object sub,
                           Py_ssize_t start=*, Py_ssize_t end=*,
                           bint partial=*) except -2
    cpdef Py_ssize_t rindex(self, object sub,
                            Py_ssize_t start=*, Py_ssize_t end=*,
                            bint partial=*) except -2
    cpdef graphemes replace(self, object old, object new,
                            Py_ssize_t count=*)
    cpdef unicode ljust(self, Py_ssize_t width, unicode fillchar=*,
                        bint wcwidth=*)
    cpdef unicode rjust(self, Py_ssize_t width, unicode fillchar=*,
                        bint wcwidth=*)
    cpdef unicode center(self, Py_ssize_t width, unicode fillchar=*,
                         bint wcwidth=*)
    cpdef graphemes join(self, seq)

    cdef bint has_str(self, str x, bint partial=*) noexcept
    cdef bint has_graphemes(self, graphemes x, bint partial=*) noexcept
    cdef Py_ssize_t count_str(self, unicode sub,
                              Py_ssize_t start=*, Py_ssize_t end=*,
                              bint partial=*) noexcept
    cdef Py_ssize_t count_graphemes(self, graphemes sub,
                                    Py_ssize_t start=*, Py_ssize_t end=*,
                                    bint partial=*) noexcept
    cdef Py_ssize_t find_str(self, unicode sub,
                             Py_ssize_t start=*, Py_ssize_t end=*,
                             bint partial=*) noexcept
    cdef Py_ssize_t rfind_str(self, unicode sub,
                              Py_ssize_t start=*, Py_ssize_t end=*,
                              bint partial=*) noexcept
    cdef Py_ssize_t find_graphemes(self, graphemes sub,
                                   Py_ssize_t start=*, Py_ssize_t end=*,
                                   bint partial=*) noexcept
    cdef Py_ssize_t rfind_graphemes(self, graphemes sub,
                                    Py_ssize_t start=*, Py_ssize_t end=*,
                                    bint partial=*) noexcept
    cdef Py_ssize_t index_str(self, unicode sub,
                              Py_ssize_t start=*, Py_ssize_t end=*,
                              bint partial=*) except -2
    cdef Py_ssize_t index_graphemes(self, graphemes sub,
                                    Py_ssize_t start=*, Py_ssize_t end=*,
                                    bint partial=*) except -2
    cdef Py_ssize_t rindex_str(self, unicode sub,
                               Py_ssize_t start=*, Py_ssize_t end=*,
                               bint partial=*) except -2
    cdef Py_ssize_t rindex_graphemes(self, graphemes sub,
                                     Py_ssize_t start=*, Py_ssize_t end=*,
                                     bint partial=*) except -2


cdef class graphemes_offsets_iter:
    cdef graphemes g
    cdef uint32_t i, l
    cdef uint32_t *off


cdef extern from *:
    """
    #define graphemes_GET_USTR(pg) (((struct graphemes_obj *)(pg))->ustr)
    #define graphemes_GET_GL(pg) (((struct graphemes_obj *)(pg))->gl)
    #define graphemes_GET_SL(pg) (((struct graphemes_obj *)(pg))->sl)
    #define graphemes_GET_OFF(pg) (((struct graphemes_obj *)(pg))->off)

    #define graphemes_CheckExact(pg) (Py_TYPE(pg) == &graphemes_type)
    #define graphemes_Check(pg) (graphemes_CheckExact(pg) \
                                 || PyObject_TypeCheck((pg), &graphemes_type))
    """
    unicode graphemes_GET_USTR(PyObject *g) noexcept
    PyObject *_graphemes_GET_USTR "graphemes_GET_USTR" (PyObject *g) noexcept
    uint32_t graphemes_GET_GL(PyObject *g) noexcept
    uint32_t graphemes_GET_SL(PyObject *g) noexcept
    uint32_t *graphemes_GET_OFF(PyObject *g) noexcept
    bint graphemes_CheckExact(PyObject *g) noexcept
    bint graphemes_Check(PyObject *g) noexcept
