#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
from libc.stdint cimport uint8_t, uint16_t, uint32_t


cpdef bint is_control_uint32(uint32_t wc) noexcept
cpdef bint is_extend_uint32(uint32_t wc) noexcept
cpdef bint is_hangul_uint32(uint32_t wc) noexcept
cpdef bint is_hangul_l(uint32_t wc) noexcept
cpdef bint is_hangul_v(uint32_t wc) noexcept
cpdef bint is_hangul_t(uint32_t wc) noexcept
cpdef bint is_hangul_lv_or_lvt(uint32_t wc) noexcept
cpdef bint is_hangul_lv(uint32_t wc) noexcept
cpdef bint is_hangul_lvt(uint32_t wc) noexcept
cpdef bint is_incb_cons_uint32(uint32_t wc) noexcept
cpdef bint is_incb_extend_uint32(uint32_t wc) noexcept
cpdef bint is_incb_linker_uint32(uint32_t wc) noexcept
cpdef bint is_postcore_uint32(uint32_t wc) noexcept
cpdef bint is_prepend_uint32(uint32_t wc) noexcept
cpdef bint is_ri_uint32(uint32_t wc) noexcept
cpdef bint is_xpicto_uint32(uint32_t wc) noexcept


cdef enum SplitRule:
    RULE_BRK = 0
    RULE_CRLF = 1
    RULE_PRECORE = 2
    RULE_CORE = 3
    RULE_POSTCORE = 4
    RULE_HANGUL = 5
    RULE_RI = 6
    RULE_RI2 = 7
    RULE_EMOJI = 8
    RULE_EMOJI_EXTEND = 9
    RULE_EMOJI_ZWJ = 10
    RULE_CBCONS = 11
    RULE_CBEXTLINK0 = 12
    RULE_CBEXTLINK1 = 13


cpdef uint16_t grapheme_split_uint32(uint16_t tran,
                                     uint32_t cur, uint32_t nxt) noexcept


cdef inline uint16_t rule_brk_below_0x300(uint32_t cur,
                                          uint32_t nxt) noexcept:
    return RULE_CRLF if cur == 13 and nxt == 10 else RULE_BRK | 0x100

cpdef uint16_t grapheme_split_ch(uint16_t tran,
                                 unicode cur, unicode nxt) except 0xffff
cpdef uint16_t grapheme_calc_tran(uint16_t tran, unicode ustr,
                                  Py_ssize_t upos=*) noexcept
cdef uint16_t grapheme_calc_tran_1byte(uint16_t tran, uint8_t *data,
                                       Py_ssize_t l) noexcept
cdef uint16_t grapheme_calc_tran_2byte(uint16_t tran, uint16_t *data,
                                       Py_ssize_t l) noexcept
cdef uint16_t grapheme_calc_tran_4byte(uint16_t tran, uint32_t *data,
                                       Py_ssize_t l) noexcept
cpdef list grapheme_split(unicode ustr)
cpdef size_t grapheme_len(unicode ustr) noexcept
cpdef size_t grapheme_off_at(unicode ustr, Py_ssize_t pos, Py_ssize_t upos=*)
cpdef unicode grapheme_at(unicode ustr, Py_ssize_t pos, Py_ssize_t upos=*)
cpdef unicode grapheme_slice(unicode ustr, Py_ssize_t startpos,
                             Py_ssize_t endpos=*, Py_ssize_t upos=*)
