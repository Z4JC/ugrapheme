#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
from libc.stdint cimport uint16_t

from ugrapheme.ugrapheme cimport SplitRule


cpdef str rule_str(SplitRule rule):
    if rule == SplitRule.RULE_BRK: return "RULE_BRK"
    elif rule == SplitRule.RULE_CRLF: return "RULE_CRLF"
    elif rule == SplitRule.RULE_PRECORE: return "RULE_PRECORE"
    elif rule == SplitRule.RULE_CORE: return "RULE_CORE"
    elif rule == SplitRule.RULE_POSTCORE: return "RULE_POSTCORE"
    elif rule == SplitRule.RULE_HANGUL: return "RULE_HANGUL"
    elif rule == SplitRule.RULE_RI: return "RULE_RI"
    elif rule == SplitRule.RULE_RI2: return "RULE_RI2"
    elif rule == SplitRule.RULE_EMOJI: return "RULE_EMOJI"
    elif rule == SplitRule.RULE_EMOJI_EXTEND: return "RULE_EMOJI_EXTEND"
    elif rule == SplitRule.RULE_EMOJI_ZWJ: return "RULE_EMOJI_ZWJ"
    elif rule == SplitRule.RULE_CBCONS: return "RULE_CBCONS"
    elif rule == SplitRule.RULE_CBEXTLINK0: return "RULE_CBEXTLINK0"
    elif rule == SplitRule.RULE_CBEXTLINK1: return "RULE_CBEXTLINK1"


cpdef str tran_str(uint16_t tran):
    cdef int brk = tran & 0x100
    cdef SplitRule rule = <SplitRule> (tran & 0xff)
    return ('BRK' if brk else '---') + ' ' + rule_str(rule) + ' ' + hex(tran)
