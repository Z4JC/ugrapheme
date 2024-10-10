# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
import pytest

from ugrapheme import grapheme_split_uint32
from ugrapheme_ucd.load_data import load_grapheme_break_test


TEST_CASES = None


def setup_module():
    global TEST_CASES
    TEST_CASES = load_grapheme_break_test()


def test_successful_test_load():
    assert len(TEST_CASES) > 100


def test_break_test_file():
    for ustr, their_breaks in TEST_CASES:
        our_breaks = find_breaks(ustr)
        if our_breaks != their_breaks:
            raise ValueError(urepr(ustr) + ' ours: %r, theirs: %r'
                             % (our_breaks, their_breaks))


def find_breaks(ustr):
    tran, l = 0, len(ustr)
    ustr += ' '
    out = []
    for i in range(l - 1):
        tran = grapheme_split_uint32(tran,
                                     ord(ustr[i]), ord(ustr[i + 1]))
        if tran & 0x100:
            out.append(i)
    out.append(l - 1)
    return out


def urepr(ustr):
    codes = []
    for ch in ustr:
        o = ord(ch)
        codes.append(('\\u%04x' % o) if o < 0x10000 else '\\U%08X' % o)
    return "'" + ''.join(codes) + "'"
