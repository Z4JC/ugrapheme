# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
import pytest

from ugrapheme_ucd.load_data import (load_grapheme_break_props,
                                     load_emoji_props, load_incb_props,
                                     EmojiProps, GraphemeBreakProps,
                                     InCBProps)


from ugrapheme.ugrapheme import (is_control_uint32, is_extend_uint32,
                                 is_postcore_uint32, is_prepend_uint32,
                                 is_ri_uint32, is_xpicto_uint32,
                                 is_incb_cons_uint32, is_incb_extend_uint32,
                                 is_incb_linker_uint32,
                                 is_hangul_uint32,
                                 is_hangul_l, is_hangul_v, is_hangul_t,
                                 is_hangul_lv, is_hangul_lvt,
                                 is_hangul_lv_or_lvt)

from ugrapheme_ucd.load_data import (load_grapheme_break_props,
                                     load_emoji_props, load_incb_props)


def setup_module(module):
    load_grapheme_break_props()
    load_emoji_props()
    load_incb_props()


def test_props_loaded():
    assert len(GraphemeBreakProps.Control) > 100
    assert len(GraphemeBreakProps.RI) > 0
    assert len(EmojiProps.Emoji) > 100
    assert len(InCBProps.Extend) > 100


def test_all_props_exhaustive():
    output_matches_set(is_control_uint32, GraphemeBreakProps.Control)
    output_matches_set(is_extend_uint32, GraphemeBreakProps.Extend)
    output_matches_set(is_hangul_l, GraphemeBreakProps.L)
    output_matches_set(is_hangul_v, GraphemeBreakProps.V)
    output_matches_set(is_hangul_t, GraphemeBreakProps.T)
    output_matches_set(is_hangul_lv, GraphemeBreakProps.LV)
    output_matches_set(is_hangul_lvt, GraphemeBreakProps.LVT)
    output_matches_set(is_hangul_lv_or_lvt,
                       GraphemeBreakProps.LV | GraphemeBreakProps.LVT)
    output_matches_set(is_hangul_uint32,
                       GraphemeBreakProps.L | GraphemeBreakProps.V
                       | GraphemeBreakProps.T | GraphemeBreakProps.LV
                       | GraphemeBreakProps.LVT)
    output_matches_set(is_prepend_uint32, GraphemeBreakProps.Prepend)
    output_matches_set(is_postcore_uint32,
                       GraphemeBreakProps.Extend | GraphemeBreakProps.ZWJ
                       | GraphemeBreakProps.SpacingMark)
    output_matches_set(is_ri_uint32, GraphemeBreakProps.RI)
    output_matches_set(is_xpicto_uint32, EmojiProps.Extended_Pictographic)
    output_matches_set(is_incb_cons_uint32, InCBProps.Consonant)
    output_matches_set(is_incb_extend_uint32, InCBProps.Extend)
    output_matches_set(is_incb_linker_uint32, InCBProps.Linker)


def output_matches_set(func, s):
    for val in range(0x110000):
        assert func(val) == (val in s)
    assert func(0x110001) == 0
    assert func(0x200000) == 0
    assert func(0xFFFFFFFF) == 0
