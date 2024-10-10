# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
import pytest

from ugrapheme import (
    grapheme_split_uint32, grapheme_split_ch, grapheme_split, grapheme_len,
    grapheme_off_at, grapheme_at, grapheme_slice, grapheme_iter,
    grapheme_offsets, center, ljust, rjust)


class TestSplits:
    def test_simple_ascii(self):
        assert grapheme_split_uint32(0, ord('a'), ord('b')) & 0x100
        assert not grapheme_split_uint32(0, 13, 10) & 0x100
        assert grapheme_split_uint32(0, 10, 13) & 0x100

        assert grapheme_split_ch(0, 'a', 'b') & 0x100
        assert not grapheme_split_ch(0, '\u000d', '\u000a') & 0x100
        assert grapheme_split_ch(0, '\u000a', '\u000d') & 0x100

        assert grapheme_len('Hi\u000d\u000athere') == 8

        assert grapheme_split('Hi\u000d\u000athere') == [
            'H', 'i', '\u000d\u000a', 't', 'h', 'e', 'r', 'e']

        assert list(grapheme_iter('Hi\u000d\u000athere')) == [
            'H', 'i', '\u000d\u000a', 't', 'h', 'e', 'r', 'e']

        assert list(grapheme_offsets('Hi\u000d\u000athere')) == [
            0, 1, 2, 4, 5, 6, 7, 8, 9]

        assert grapheme_off_at('Hi\u000d\u000athere', 3) == 4
        assert grapheme_at('Hi\u000d\u000athere', 3) == 't'

        assert grapheme_slice('Hi\u000d\u000athere', 3) == 'there'
        assert grapheme_slice('Hi\u000d\u000athere', 3, 6) == 'the'
        assert grapheme_slice('Hi\u000d\u000athere', 0, 3) == 'Hi\u000d\u000a'

        assert grapheme_slice('Hi\u000d\u000athere', 3, 100) == 'there'
        assert grapheme_slice('Hi\u000d\u000athere',
                              -100, 3) == 'Hi\u000d\u000a'
        assert grapheme_slice('Hi\u000d\u000athere',
                              -100, 100) == 'Hi\u000d\u000athere'
        assert grapheme_slice('Hi\u000d\u000athere', -100, -90) == ''
        assert grapheme_slice('Hi\u000d\u000athere', 90, 100) == ''

        assert grapheme_at('Hi\u000d\u000athere', -1) == ''
        assert grapheme_off_at('Hi\u000d\u000athere', -1) == 0
        assert grapheme_at('Hi\u000d\u000athere', 100) == ''
        assert grapheme_off_at('Hi\u000d\u000athere',
                               100) == len('Hi\u000d\u000athere')

    def test_emoji_string(self):
        scientist = '👩🏽‍🔬'
        flag = '🏴󠁧󠁢󠁳󠁣󠁴󠁿'
        s = scientist + flag + 'Hi'

        assert grapheme_len(s) == 4
        assert grapheme_at(s, 0) == scientist
        assert grapheme_at(s, 1) == flag
        assert grapheme_at(s, 2) == 'H'
        assert grapheme_at(s, 3) == 'i'

        assert grapheme_slice(s, 0, 2) == scientist + flag
        assert grapheme_slice(s, 2) == 'Hi'
        assert center(s, 10, '-') == '--' + s + '--'
        assert ljust(s, 10, '-') == s + '----'
        assert rjust(s, 10, '-') == '----' + s

        assert grapheme_split(s) == [scientist, flag, 'H', 'i']
        assert list(grapheme_iter(s)) == [scientist, flag, 'H', 'i']
        assert grapheme_off_at(s, 1) == len(scientist)
        assert grapheme_off_at(s, 2) == len(scientist) + len(flag)
        assert grapheme_off_at(s, 3) == len(scientist) + len(flag) + 1

        assert list(grapheme_offsets(s)) == [
            0, len(scientist), len(scientist) + len(flag),
            len(scientist) + len(flag) + 1, len(scientist) + len(flag) + 2]

        assert grapheme_slice(s, 2, 100) == 'Hi'
        assert grapheme_slice(s, -100, 2) == scientist + flag
        assert grapheme_slice(s, -100, 100) == s
        assert grapheme_slice(s, -100, -90) == ''
        assert grapheme_slice(s, 90, 100) == ''

        assert grapheme_at(s, -1) == ''
        assert grapheme_off_at(s, -1) == 0
        assert grapheme_at(s, 100) == ''
        assert grapheme_off_at(s, 100) == len(s)

        tran = 0
        for ch_l, ch_r in zip(scientist[:-1], scientist[1:]):
            tran = grapheme_split_ch(tran, ch_l, ch_r)
            assert not tran & 0x100

        tran = grapheme_split_ch(tran, scientist[-1], flag[0])
        assert tran & 0x100

    def test_blank(self):
        assert grapheme_len('') == 0
        assert grapheme_split('') == []
        assert list(grapheme_iter('')) == []
        assert grapheme_at('', 0) == ''
        assert grapheme_off_at('', 0) == 0
        assert grapheme_at('', -1) == ''
        assert grapheme_at('', 1) == ''
        assert grapheme_off_at('', -1) == 0
        assert grapheme_off_at('', 1) == 0
        assert grapheme_slice('', 0, 0) == ''
        assert grapheme_slice('', -100, -90) == ''
        assert grapheme_slice('', 90, 100) == ''
        assert grapheme_slice('', -100, 100) == ''

        assert center('', 5) == '     '
        assert ljust('', 5) == '     '
        assert rjust('', 5) == '     '

        assert list(grapheme_offsets('')) == []
