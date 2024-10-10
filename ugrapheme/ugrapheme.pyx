#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
from cpython.pyport cimport PY_SSIZE_T_MAX
from cpython.unicode cimport (PyUnicode_GetLength, PyUnicode_GET_LENGTH,
                              PyUnicode_KIND, PyUnicode_DATA, PyUnicode_READ,
                              PyUnicode_1BYTE_DATA, PyUnicode_1BYTE_KIND,
                              PyUnicode_2BYTE_KIND, PyUnicode_4BYTE_KIND,
                              PyUnicode_FromKindAndData)
from libc.stdint cimport uint8_t, uint16_t, uint32_t

from ugrapheme.tables.control cimport (
    _CTRL_HI_PHY, _CTRL_HI_MINVAL, _CTRL_HI_MAXVAL,
    _CTRL_LO_PHY, _CTRL_LO_MINVAL, _CTRL_LO_MAXVAL)
from ugrapheme.tables.extend cimport (
    _EXT_LO1_PHY, _EXT_LO1_MINVAL, _EXT_LO1_MAXVAL,
    _EXT_LO2_PHY, _EXT_LO2_MINVAL, _EXT_LO2_MAXVAL,
    _EXT_HI_PHY, _EXT_HI_MINVAL, _EXT_HI_MAXVAL)
from ugrapheme.tables.incb cimport (
    _INCB_C_PHY, _INCB_C_MINVAL, _INCB_C_MAXVAL,
    _INCB_EX_LO1_PHY, _INCB_EX_LO1_MINVAL, _INCB_EX_LO1_MAXVAL,
    _INCB_EX_LO2_PHY, _INCB_EX_LO2_MINVAL,_INCB_EX_LO2_MAXVAL)
from ugrapheme.tables.postcore cimport (
    _POST_LO_PHY, _POST_LO_MINVAL, _POST_LO_MAXVAL,
    _POST_HI_PHY, _POST_HI_MINVAL, _POST_HI_MAXVAL)
from ugrapheme.tables.prepend cimport (
    _PREP_HI_PHY, _PREP_HI_MINVAL, _PREP_HI_MAXVAL,
    _PREP_LO_PHY, _PREP_LO_MINVAL, _PREP_LO_MAXVAL)
from ugrapheme.tables.xpicto cimport _XPIC_PHY, _XPIC_MINVAL, _XPIC_MAXVAL


cpdef bint is_control_uint32(uint32_t wc) noexcept:
    cdef uint32_t v = 0
    if wc - _CTRL_LO_MINVAL <= (_CTRL_LO_MAXVAL - _CTRL_LO_MINVAL):
        v = wc - _CTRL_LO_MINVAL
        return _CTRL_LO_PHY[(_CTRL_LO_PHY[v >> 8] << 5)
                        + ((v & 255) >> 3)] & (1 << (v & 7))
    if wc - _CTRL_HI_MINVAL <= (_CTRL_HI_MAXVAL - _CTRL_HI_MINVAL):
        v = wc - _CTRL_HI_MINVAL
        return _CTRL_HI_PHY[(_CTRL_HI_PHY[v >> 6] << 3)
                       + ((v & 63) >> 3)] & (1 << (v & 7))
    return 0


cpdef bint is_extend_uint32(uint32_t wc) noexcept:
    cdef uint32_t v = 0
    if wc < _EXT_LO1_MINVAL:
        return False
    if wc <= _EXT_LO1_MAXVAL:
        v = wc - _EXT_LO1_MINVAL
        return _EXT_LO1_PHY[(_EXT_LO1_PHY[v >> 6] << 3)
                            + ((v & 63) >> 3)] & (1 << (v & 7))
    if wc - _EXT_LO2_MINVAL <= (_EXT_LO2_MAXVAL - _EXT_LO2_MINVAL):
        v = wc - _EXT_LO2_MINVAL
        return _EXT_LO2_PHY[(_EXT_LO2_PHY[v >> 7] << 4)
                            + ((v & 127) >> 3)] & (1 << (v & 7))
    if wc - _EXT_HI_MINVAL <= (_EXT_HI_MAXVAL - _EXT_HI_MINVAL):
        v = wc - _EXT_HI_MINVAL
        return _EXT_HI_PHY[(_EXT_HI_PHY[v >> 5] << 2)
                           + ((v & 31) >> 3)] & (1 << (v & 7))
    return False


# Runs in at most 4 compares
cpdef bint is_hangul_uint32(uint32_t wc) noexcept:
    if wc - 0x1100U > 0xd7fbU - 0x1100U:  # 1
        return False
    # 0x1100 <= wc <= 0xd7fb
    if wc - 0xa960U <= 0xd7a3U - 0xa960U:  # 2
        # 0xa960 <= wc <= 0xd7a3
        if wc - 0xa97dU < 0xac00U - 0xa97dU:  # 3
            # 0xa97c < wc < 0xac00
            return False
        # 0xa960 <= 0xa97c or 0xac00 <= wc <= 0xd7a3
        return True
    # 0x1100 <= wc < 0xa960 or 0xd7a3 < wc < 0xd7fb
    if wc - 0x1200U < 0xd7b0U - 0x1200U:  # 3
        # 0x11ff < wc < 0xa960 or 0xd7a3 < wc < 0xd7b0:
        return False
    # 0x1100 <= wc <= 0x11ff or 0xd7b0 <= wc <= 0xd7fb
    if wc - 0xd7c7U < 0xd7cbU - 0xd7c7U:  # 4
        # 0xd7c6 < wc < 0xd7cb
        return False
    # 0x1100 <= wc <= 0x11ff or 0xd7b0 <= wc <= 0xd7c6 or 0xd7cb <= 0xd7fb
    return True


cpdef bint is_hangul_l(uint32_t wc) noexcept:
    return (wc - 0x1100U <= 0x115fU - 0x1100U
            or wc - 0xa960U <= 0xa97cU - 0xa960U)


cpdef bint is_hangul_v(uint32_t wc) noexcept:
    return (wc - 0x1160U <= 0x11a7U - 0x1160U
            or wc - 0xd7b0U <= 0xd7c6 - 0xd7b0U)


cpdef bint is_hangul_t(uint32_t wc) noexcept:
    return (wc - 0x11a8U <= 0x11ffU - 0x11a8U
            or wc - 0xd7cbU <= 0xd7fbU - 0xd7cbU)


cpdef bint is_hangul_lv_or_lvt(uint32_t wc) noexcept:
    return wc - 0xac00U <= 0xd7a3U - 0xac00U


cdef extern from *:
    """
    # include <stdint.h>

    static inline uint32_t _is_hangul_lv(uint32_t wc) {
        return (wc - 0xac00U <= 0xd7a3U - 0xac00U) && !((wc - 0xac00U) % 28);
    }

    static inline uint32_t _is_hangul_lvt(uint32_t wc) {
        return (wc - 0xac00U <= 0xd7a3U - 0xac00U) && ((wc - 0xac00U) % 28);
    }
    """
    cdef bint _is_hangul_lv(uint32_t wc)
    cdef bint _is_hangul_lvt(uint32_t wc)


cpdef bint is_hangul_lv(uint32_t wc) noexcept:
    return _is_hangul_lv(wc)


cpdef bint is_hangul_lvt(uint32_t wc) noexcept:
    return _is_hangul_lvt(wc)


cpdef bint is_incb_cons_uint32(uint32_t wc) noexcept:
   cdef uint32_t v = wc - _INCB_C_MINVAL
   if v <= (_INCB_C_MAXVAL - _INCB_C_MINVAL):
       return _INCB_C_PHY[(_INCB_C_PHY[v >> 4] << 1)
                          + ((v & 15) >> 3)] & (1 << (v & 7))


cpdef bint is_incb_extend_uint32(uint32_t wc) noexcept:
    cdef uint32_t v = 0
    if wc - _INCB_EX_LO1_MINVAL <= _INCB_EX_LO1_MAXVAL - _INCB_EX_LO1_MINVAL:
        v = wc - _INCB_EX_LO1_MINVAL
        return _INCB_EX_LO1_PHY[(_INCB_EX_LO1_PHY[v >> 6] << 3)
                                + ((v & 63) >> 3)] & (1 << (v & 7))
    if wc - _INCB_EX_LO2_MINVAL <= _INCB_EX_LO2_MAXVAL - _INCB_EX_LO2_MINVAL:
        v = wc - _INCB_EX_LO2_MINVAL
        return _INCB_EX_LO2_PHY[(_INCB_EX_LO2_PHY[v >> 7] << 4)
                                + ((v & 127) >> 3)] & (1 << (v & 7))
    return (wc - 0xe0020U <= 0xe007fU - 0xe0020U
            or wc - 0xe0100U <= 0xe01efU - 0xe0100U)


cpdef bint is_incb_linker_uint32(uint32_t wc) noexcept:
    if wc - 0x94dU > (0xd4dU - 0x94dU):
        return False
    if wc & 0xff == 0xcd:
        return ((wc >> 8) - 9U) <= 1U
    if wc & 0xff == 0x4d:
        return (wc >> 8) != 0x0a
    return False


cpdef bint is_postcore_uint32(uint32_t wc) noexcept:
    cdef uint32_t v = 0
    if wc - _POST_LO_MINVAL <= (_POST_LO_MAXVAL - _POST_LO_MINVAL):
        v = wc - _POST_LO_MINVAL
        return _POST_LO_PHY[(_POST_LO_PHY[v >> 7] << 4)
                            + ((v & 127) >> 3)] & (1 << (v & 7))
    if wc - _POST_HI_MINVAL <= (_POST_HI_MAXVAL - _POST_HI_MINVAL):
        v = wc - _POST_HI_MINVAL
        return _POST_HI_PHY[(_POST_HI_PHY[v >> 5] << 2)
                            + ((v & 31) >> 3)] & (1 << (v & 7))
    return 0


cpdef bint is_prepend_uint32(uint32_t wc) noexcept:
    cdef uint32_t v = 0
    if wc - _PREP_LO_MINVAL <= (_PREP_LO_MAXVAL - _PREP_LO_MINVAL):
        v = wc - _PREP_LO_MINVAL
        return _PREP_LO_PHY[(_PREP_LO_PHY[v >> 5] << 2)
                            + ((v & 31) >> 3)] & (1 << (v & 7))
    if wc - _PREP_HI_MINVAL <= (_PREP_HI_MAXVAL - _PREP_HI_MINVAL):
        v = wc - _PREP_HI_MINVAL
        return _PREP_HI_PHY[(_PREP_HI_PHY[v >> 6] << 3)
                            + ((v & 63) >> 3)] & (1 << (v & 7))
    return 0


cpdef bint is_xpicto_uint32(uint32_t wc) noexcept:
    cdef uint32_t v = wc - _XPIC_MINVAL
    if v <= (_XPIC_MAXVAL - _XPIC_MINVAL):
        return _XPIC_PHY[(_XPIC_PHY[v >> 8] << 5)
                         + ((v & 255) >> 3)] & (1 << (v & 7))


cpdef bint is_ri_uint32(uint32_t wc) noexcept:
    return wc - 0x1f1e6U <= (0x1f1ffU - 0x1f1e6U)


cdef inline uint16_t rule_brk(uint32_t cur, uint32_t nxt) noexcept:
    if cur == 13:
        return RULE_CRLF if nxt == 10 else RULE_BRK | 0x100
    if cur == 10:
        return RULE_BRK | 0x100
    if is_control_uint32(cur):
        return RULE_BRK | 0x100
    if is_prepend_uint32(cur):
        return rule_precore(nxt)
    return rule_core(cur, nxt)


cdef inline uint16_t rule_crlf() noexcept:
    return RULE_BRK | 0x100


cdef inline uint16_t rule_precore(uint32_t nxt) noexcept:
    if is_prepend_uint32(nxt):
        return RULE_PRECORE
    if nxt == 13 or nxt == 10 or is_control_uint32(nxt):
        return RULE_BRK | 0x100
    return RULE_CORE


cdef inline uint16_t rule_core(uint32_t cur, uint32_t nxt) noexcept:
    if is_hangul_uint32(cur):
        return rule_hangul(cur, nxt)
    if is_ri_uint32(cur):
        return rule_ri(cur, nxt)
    if is_xpicto_uint32(cur):
        return rule_emoji(cur, nxt)
    if is_incb_cons_uint32(cur):
        return rule_cbcons(cur, nxt)
    if is_postcore_uint32(nxt):
        return RULE_POSTCORE
    return RULE_BRK | 0x100


cdef inline uint16_t rule_postcore(uint32_t nxt) noexcept:
    return (RULE_POSTCORE if is_postcore_uint32(nxt)
            else (RULE_BRK | 0x100))


cdef inline uint16_t rule_hangul(uint32_t cur, uint32_t nxt) noexcept:
    if is_hangul_uint32(nxt):
        if is_hangul_l(cur) and not is_hangul_t(nxt):
            return RULE_HANGUL
        if ((is_hangul_lv(cur) or is_hangul_v(cur))
            and (is_hangul_v(nxt) or is_hangul_t(nxt))):
            return RULE_HANGUL
        if is_hangul_t(nxt) and (is_hangul_lvt(cur) or is_hangul_t(cur)):
            return RULE_HANGUL
        return RULE_HANGUL | 0x100
    return rule_postcore(nxt)


cdef inline uint16_t rule_ri(uint32_t cur, uint32_t nxt) noexcept:
    if is_ri_uint32(nxt):
        return RULE_RI2
    return rule_postcore(nxt)


cdef inline uint16_t rule_emoji(uint32_t cur, uint32_t nxt) noexcept:
    if nxt == 0x200d:
        return RULE_EMOJI_ZWJ
    if is_extend_uint32(nxt):
        return RULE_EMOJI_EXTEND
    return rule_postcore(nxt)


cdef inline uint16_t rule_emoji_extend(uint32_t cur, uint32_t nxt) noexcept:
    if nxt == 0x200d:
        return RULE_EMOJI_ZWJ
    if is_extend_uint32(nxt):
        return RULE_EMOJI_EXTEND
    return rule_postcore(nxt)


cdef inline uint16_t rule_emoji_zwj(uint32_t cur, uint32_t nxt) noexcept:
    return RULE_EMOJI if is_xpicto_uint32(nxt) else rule_postcore(nxt)


cdef inline uint16_t rule_cbcons(uint32_t cur, uint32_t nxt) noexcept:
    if is_incb_extend_uint32(nxt):
        return RULE_CBEXTLINK0
    if is_incb_linker_uint32(nxt):
        return RULE_CBEXTLINK1
    return rule_postcore(nxt)


cdef inline uint16_t rule_cbextlink0(uint32_t cur, uint32_t nxt) noexcept:
    if is_incb_linker_uint32(nxt):
        return RULE_CBEXTLINK1
    if is_incb_extend_uint32(nxt):
        return RULE_CBEXTLINK0
    return rule_postcore(nxt)


cdef inline uint16_t rule_cbextlink1(uint32_t cur, uint32_t nxt) noexcept:
    if is_incb_linker_uint32(nxt):
        return RULE_CBEXTLINK1
    if is_incb_extend_uint32(nxt):
        return RULE_CBEXTLINK1
    if is_incb_cons_uint32(nxt):
        return RULE_CBCONS
    return rule_postcore(nxt)


cpdef uint16_t grapheme_split_uint32(uint16_t tran,
                                     uint32_t cur, uint32_t nxt) noexcept:
    """Checks if the current and next codepoints belong to the same grapheme.

    This is a low-level method; consider using higher-level calls.

    tran is the internal transition state, can be 0 on the first call
    cur is the current unicode codepoint, as an unsigned 32-bit integer
    nxt is the next unicode codepoint, as an unsigned 32-bit integer

    Returns an internal transition state that should be passed to the next
    call of grapheme_split_uint32. If the returned state & 0x100 is True,
    cur and nxt belong to different graphemes, otherwise they belong
    to the same grapheme."""
    if cur < 0x300 and nxt < 0x300:
        return rule_brk_below_0x300(cur, nxt)
    return _grapheme_split_uint32(tran, cur, nxt)


cdef inline uint16_t _grapheme_split_uint32(
     uint16_t tran, uint32_t cur, uint32_t nxt) noexcept:
    cdef SplitRule rule = <SplitRule> (tran & 0xff)
    if rule == RULE_BRK: return rule_brk(cur, nxt)
    elif rule == RULE_CRLF: return rule_crlf()
    elif rule == RULE_PRECORE: return rule_precore(nxt)
    elif rule == RULE_CORE: return rule_core(cur, nxt)
    elif rule == RULE_POSTCORE: return rule_postcore(nxt)
    elif rule == RULE_HANGUL: return rule_hangul(cur, nxt)
    elif rule == RULE_RI: return rule_ri(cur, nxt)
    elif rule == RULE_RI2: return rule_postcore(nxt)
    elif rule == RULE_EMOJI: return rule_emoji(cur, nxt)
    elif rule == RULE_EMOJI_EXTEND: return rule_emoji_extend(cur, nxt)
    elif rule == RULE_EMOJI_ZWJ: return rule_emoji_zwj(cur, nxt)
    elif rule == RULE_CBCONS: return rule_cbcons(cur, nxt)
    elif rule == RULE_CBEXTLINK0: return rule_cbextlink0(cur, nxt)
    elif rule == RULE_CBEXTLINK1: return rule_cbextlink1(cur, nxt)
    return 0


cpdef uint16_t grapheme_split_ch(uint16_t tran,
                                 unicode cur, unicode nxt) except 0xffff:
    """Checks if the current and next characters belong to the same grapheme.

    This is a low-level method; consider using higher-level calls.

    tran is the internal transition state, can be 0 on the first call
    cur is the current unicode character, as a python string
    nxt is the next unicode character, as a python string

    Returns an internal transition state that should be passed to the next
    call of grapheme_split_ch. If the returned state & 0x100 is True, cur and
    nxt belong to different graphemes, otherwise they belong to the same
    grapheme."""
    if PyUnicode_GetLength(cur) != 1:
        raise ValueError("cur must be a single char, got [%s]" % cur)
    if PyUnicode_GetLength(nxt) != 1:
        raise ValueError("nxt must be a single char, got [%s]" % nxt)
    cdef unsigned int kind1 = PyUnicode_KIND(cur), kind2 = PyUnicode_KIND(nxt)
    if kind1 == PyUnicode_1BYTE_KIND and kind2 == PyUnicode_1BYTE_KIND:
        return rule_brk_below_0x300(PyUnicode_1BYTE_DATA(cur)[0],
                                    PyUnicode_1BYTE_DATA(nxt)[0])
    cdef uint32_t cur32 = PyUnicode_READ(kind1, PyUnicode_DATA(cur), 0)
    cdef uint32_t nxt32 = PyUnicode_READ(kind2, PyUnicode_DATA(nxt), 0)
    return _grapheme_split_uint32(tran, cur32, nxt32)


cpdef list grapheme_split(unicode ustr):
    """Splits the string ustr into a list of strings that are graphemes.

       Example: grapheme_split('Hi🇭🇷') -> ['H', 'i', '🇭🇷']

       Notice that simply doing list('Hi🇭🇷') returns 4 characters, where
       the last 2 characters are unreadable unicode codepoints."""
    cdef size_t l = PyUnicode_GetLength(ustr)
    if l == 0:
        return []

    cdef unsigned int kind = PyUnicode_KIND(ustr)
    if kind == PyUnicode_1BYTE_KIND:
        return _grapheme_split_u8(<uint8_t *> PyUnicode_DATA(ustr), l)
    elif kind == PyUnicode_2BYTE_KIND:
        return _grapheme_split_u16(<uint16_t *> PyUnicode_DATA(ustr), l)
    elif kind == PyUnicode_4BYTE_KIND:
        return _grapheme_split_u32(<uint32_t *> PyUnicode_DATA(ustr), l)


cdef inline list _grapheme_split_u8(uint8_t *data, size_t l):
    cdef list out = []
    cdef size_t i = 0, last_i = 0

    for i in range(1, l):
        if rule_brk_below_0x300(data[i - 1], data[i]) == RULE_CRLF:
            continue
        out.append(PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND,
                                             &data[last_i], i - last_i))
        last_i = i
    out.append(PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND,
                                         &data[last_i], l - last_i))
    return out


cdef inline list _grapheme_split_u16(uint16_t *data, size_t l):
    cdef list out = []
    cdef uint16_t tran = 0
    cdef size_t i = 0, last_i = 0

    for i in range(1, l):
        tran = grapheme_split_uint32(tran, data[i - 1], data[i])
        if tran & 0x100 == 0:
            continue
        out.append(PyUnicode_FromKindAndData(PyUnicode_2BYTE_KIND,
                                             &data[last_i], i - last_i))
        last_i = i
    out.append(PyUnicode_FromKindAndData(PyUnicode_2BYTE_KIND,
                                         &data[last_i], l - last_i))
    return out


cdef inline list _grapheme_split_u32(uint32_t *data, size_t l):
    cdef list out = []
    cdef uint16_t tran = 0
    cdef size_t i = 0, last_i = 0

    for i in range(1, l):
        tran = grapheme_split_uint32(tran, data[i - 1], data[i])
        if tran & 0x100 == 0:
            continue
        out.append(PyUnicode_FromKindAndData(PyUnicode_4BYTE_KIND,
                                             &data[last_i], i - last_i))
        last_i = i
    out.append(PyUnicode_FromKindAndData(PyUnicode_4BYTE_KIND,
                                         &data[last_i], l - last_i))
    return out


cpdef size_t grapheme_len(unicode ustr) noexcept:
    """Returns the length of string ustr counted in graphemes.

       Example: grapheme_len('Hi🇭🇷') -> 3

       Notice that calling python's len('Hi🇭🇷') returns 4, as the flag
       character consists of 2 unreadable unicode codepoints.

       The grapheme length of the string is 3, as the string is split into
       three distinct graphemes:
            grapheme_split('Hi🇭🇷') -> ['H', 'i', '🇭🇷']
    """
    cdef size_t l = PyUnicode_GetLength(ustr)
    if l == 0:
        return 0

    cdef unsigned int kind = PyUnicode_KIND(ustr)
    if kind == PyUnicode_1BYTE_KIND:
        return _grapheme_len_uXX(<uint8_t *> PyUnicode_DATA(ustr), l)
    elif kind == PyUnicode_2BYTE_KIND:
        return _grapheme_len_uXX(<uint16_t *> PyUnicode_DATA(ustr), l)
    elif kind == PyUnicode_4BYTE_KIND:
        return _grapheme_len_uXX(<uint32_t *> PyUnicode_DATA(ustr), l)


ctypedef fused uintXX_t:
    uint8_t
    uint16_t
    uint32_t


cdef inline size_t _grapheme_len_uXX(uintXX_t *data, size_t l) noexcept:
    cdef uint16_t tran = 0
    cdef size_t i = 0, count = 1

    for i in range(1, l):
        if uintXX_t is uint8_t:
            tran = rule_brk_below_0x300(data[i - 1], data[i])
        else:
            tran = grapheme_split_uint32(tran, data[i - 1], data[i])
        count += (tran & 0x100) != 0
    return count


cpdef size_t grapheme_off_at(unicode ustr, Py_ssize_t pos, Py_ssize_t upos=0):
    """Returns the index (offset) of grapheme at pos inside the string ustr.

    Graphemes can occupy several unicode codepoints inside a string.
    For example, in the string '👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi', the letter 'H' comes after
    the scientist and the flag. So to the reader, letter 'H' is the
    third visible symbol, or, counting from zero, in position 2.

    However, it takes many unicode codepoints to represent the scientist
    and the flag, so the letter 'H' is at index 11 inside the string.

    Example:
           grapheme_off_at('👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi', 2) -> 11

    If the position pos is negative, 0 is returned.
    If the position pos is past the end of string, the length of the string
    is returned.

    With optional upos, instead of counting positions from the beginning of
    the string, the substring starting at index upos is used instead.
    """
    if pos <= 0:
        return 0

    cdef size_t l = PyUnicode_GetLength(ustr) - upos
    if pos >= l:
        return l

    cdef unsigned int kind = PyUnicode_KIND(ustr)
    if kind == PyUnicode_1BYTE_KIND:
        return _grapheme_off_at_uXX(<uint8_t *> PyUnicode_DATA(ustr) + upos,
                                    pos, l)
    elif kind == PyUnicode_2BYTE_KIND:
        return _grapheme_off_at_uXX(<uint16_t *> PyUnicode_DATA(ustr) + upos,
                                    pos, l)
    elif kind == PyUnicode_4BYTE_KIND:
        return _grapheme_off_at_uXX(<uint32_t *> PyUnicode_DATA(ustr) + upos,
                                    pos, l)


cdef inline size_t _grapheme_off_at_uXX(uintXX_t *data, size_t pos,
                                        size_t l) noexcept:
    cdef uint16_t tran = 0
    cdef size_t i = 0, count = 0

    if pos == 0:
        return 0

    for i in range(1, l):
        if uintXX_t is uint8_t:
            tran = rule_brk_below_0x300(data[i - 1], data[i])
        else:
            tran = grapheme_split_uint32(tran, data[i - 1], data[i])
        if not tran & 0x100:
            continue
        count += 1
        if count == pos:
            return i
    return l


cpdef unicode grapheme_at(unicode ustr, Py_ssize_t pos, Py_ssize_t upos=0):
    """Returns grapheme at position pos inside the string ustr.

    Graphemes can occupy several unicode codepoints inside a string.
    For example, in the string '👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi', the letter 'H' comes after
    the scientist 👩🏽‍🔬and the flag. To the observer, letter 'H' is the
    third visible symbol, or, counting from zero, in position 2. In the
    underlying python string, there are many codepoints needed for the
    scientist and flag characters, so 'H' is at index 11 inside the underlying
    python string.

    Example:
           grapheme_at('👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi', 2) -> 'H'

    If the position pos is negative, an empty string is returned
    If the position pos is past the end of string, an empty string is returned

    With optional upos, instead of counting positions from the beginning of
    the string, the substring starting at index upos is used instead.
    """
    cdef size_t l = PyUnicode_GetLength(ustr) - upos
    if pos >= l or pos < 0:
        return ''

    cdef unsigned int kind = PyUnicode_KIND(ustr)
    if kind == PyUnicode_1BYTE_KIND:
        return _grapheme_at_uXX(<uint8_t *> PyUnicode_DATA(ustr) + upos,
                                pos, l)
    elif kind == PyUnicode_2BYTE_KIND:
        return _grapheme_at_uXX(<uint16_t *> PyUnicode_DATA(ustr) + upos,
                                pos, l)
    elif kind == PyUnicode_4BYTE_KIND:
        return _grapheme_at_uXX(<uint32_t *> PyUnicode_DATA(ustr) + upos,
                                pos, l)


cdef inline unicode _grapheme_at_uXX(uintXX_t *data, size_t pos,
                                     size_t l):
    cdef size_t start = _grapheme_off_at_uXX(data, pos, l)
    if start >= l:
        return ''
    cdef size_t sub_l = _grapheme_off_at_uXX(data + start, 1, l - start)

    if uintXX_t is uint8_t:
        return PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND,
                                         &data[start], sub_l)
    elif uintXX_t is uint16_t:
        return PyUnicode_FromKindAndData(PyUnicode_2BYTE_KIND,
                                         &data[start], sub_l)
    elif uintXX_t is uint32_t:
        return PyUnicode_FromKindAndData(PyUnicode_4BYTE_KIND,
                                         &data[start], sub_l)


cpdef unicode grapheme_slice(unicode ustr,
                             Py_ssize_t startpos,
                             Py_ssize_t endpos=PY_SSIZE_T_MAX,
                             Py_ssize_t upos=0):
    """Returns a slice of ustr from grapheme at startpos ending at endpos.

    Graphemes can occupy several unicode codepoints inside a string.
    For example, in the string '👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi', the letter 'H' comes after
    the scientist and the flag. Extracting the word Hi visually means
    extracting the string starting at grapheme position 2 and ending
    at position 4.

    With optional upos, works on a substring of ustr starting at upos.
    A portion of ustr that is in the range specified by startpos and the
    optional endpos is returned. If no portion of ustr is in the specified
    range, a blank string is returned.

    Examples:
        grapheme_slice('👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi', 2, 4) -> 'Hi'
        grapheme_slice('👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi', 2) -> 'Hi'
        grapheme_slice('👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi', 0, 1) -> '👩🏽‍🔬'

    Notice that if you were using python's standard string slicing operations,
    you would have to know that the scientist grapheme needs 4 codepoints
    and that the flag used here needs 7 codepoints, so if you had:
        s = '👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi'
     then:
        s[11:13] -> 'Hi'
        s[0:4] -> '👩🏽‍🔬'
    """

    cdef size_t l = PyUnicode_GetLength(ustr) - upos
    if startpos < 0:
        startpos = 0
    if startpos >= l or endpos <= startpos:
        return ''

    cdef unsigned int kind = PyUnicode_KIND(ustr)
    if kind == PyUnicode_1BYTE_KIND:
        return _grapheme_slice_uXX(<uint8_t *> PyUnicode_DATA(ustr) + upos,
                                   startpos, endpos, l)
    elif kind == PyUnicode_2BYTE_KIND:
        return _grapheme_slice_uXX(<uint16_t *> PyUnicode_DATA(ustr) + upos,
                                   startpos, endpos, l)
    elif kind == PyUnicode_4BYTE_KIND:
        return _grapheme_slice_uXX(<uint32_t *> PyUnicode_DATA(ustr) + upos,
                                   startpos, endpos, l)


cdef inline unicode _grapheme_slice_uXX(uintXX_t *data,
                                        size_t startpos, size_t endpos,
                                        size_t l):
    cdef size_t ustart = _grapheme_off_at_uXX(data, startpos, l)
    if ustart >= l:
        return ''
    cdef size_t sub_l = (_grapheme_off_at_uXX(data + ustart,
                                              endpos - startpos, l - ustart)
                         if endpos != PY_SSIZE_T_MAX else l - ustart)

    if uintXX_t is uint8_t:
        return PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND,
                                         &data[ustart], sub_l)
    elif uintXX_t is uint16_t:
        return PyUnicode_FromKindAndData(PyUnicode_2BYTE_KIND,
                                         &data[ustart], sub_l)
    elif uintXX_t is uint32_t:
        return PyUnicode_FromKindAndData(PyUnicode_4BYTE_KIND,
                                         &data[ustart], sub_l)


cpdef uint16_t grapheme_calc_tran(uint16_t tran, unicode ustr,
                                  Py_ssize_t upos=0) noexcept:
    """Calculates the internal transition state for the given string.

    This is a low-level method; consider using higher-level calls.

    The decision on whether the two neighboring characters belong to the
    same grapheme depends on the internal transition state, the current
    unicode character being examined and the following (next) character.

    grapheme_calc_tran can be used to calculate a transition state
    prior to the current character being examined.
    """
    cdef Py_ssize_t l = PyUnicode_GET_LENGTH(ustr) - upos
    if upos >= l or upos < 0:
        return 0

    cdef unsigned int kind = PyUnicode_KIND(ustr)
    if kind == PyUnicode_1BYTE_KIND:
        return _grapheme_calc_tran(tran, <uint8_t *> PyUnicode_DATA(ustr)
                                   + upos, l)
    elif kind == PyUnicode_2BYTE_KIND:
        return _grapheme_calc_tran(tran, <uint16_t *> PyUnicode_DATA(ustr)
                                   + upos, l)
    elif kind == PyUnicode_4BYTE_KIND:
        return _grapheme_calc_tran(tran, <uint32_t *> PyUnicode_DATA(ustr)
                                   + upos, l)


cdef uint16_t grapheme_calc_tran_1byte(uint16_t tran, uint8_t *data,
                                       Py_ssize_t l) noexcept:
    return _grapheme_calc_tran(tran, data, l)


cdef uint16_t grapheme_calc_tran_2byte(uint16_t tran, uint16_t *data,
                                       Py_ssize_t l) noexcept:
    return _grapheme_calc_tran(tran, data, l)


cdef uint16_t grapheme_calc_tran_4byte(uint16_t tran, uint32_t *data,
                                       Py_ssize_t l) noexcept:
    return _grapheme_calc_tran(tran, data, l)


cdef inline uint16_t _grapheme_calc_tran(uint16_t tran,
                                         uintXX_t *data, uint32_t l) noexcept:
    cdef size_t i = 0

    for i in range(1, l):
        if uintXX_t is uint8_t:
            tran = rule_brk_below_0x300(data[i - 1], data[i])
        else:
            tran = grapheme_split_uint32(tran, data[i - 1], data[i])
    return tran
