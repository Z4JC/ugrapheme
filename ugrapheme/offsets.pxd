#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD

from cpython cimport array
from libc.stdint cimport uint8_t, uint16_t, uint32_t


cpdef array.array grapheme_offsets(unicode ustr)
cdef uint32_t _grapheme_offsets(unicode ustr, size_t l,
                                uint32_t *out,
                                uint32_t initial, uint32_t upos) noexcept

cdef uint32_t _grapheme_offsets_1byte_recalc(uint8_t *ch8_ustr, size_t l,
                                             uint32_t *out, uint32_t initial,
                                             uint32_t upos) noexcept
cdef uint32_t _grapheme_offsets_2byte_recalc(uint16_t *ch16_ustr, size_t l,
                                             uint32_t *out, uint32_t initial,
                                             uint32_t upos) noexcept
cdef uint32_t _grapheme_offsets_4byte_recalc(uint32_t *ch32_ustr, size_t l,
                                             uint32_t *out, uint32_t initial,
                                             uint32_t upos) noexcept
