import os
import sys


def data_path(base):
    return os.path.join(os.path.join(os.path.dirname(
        os.path.abspath(__file__)), 'data'), base)


DERIVED_CORE_PROPERTIES_TXT = data_path('DerivedCoreProperties.txt')
GRAPHEME_BREAK_PROPRETY_TXT = data_path('GraphemeBreakProperty.txt')
GRAPHEME_BREAK_TEST_TXT = data_path('GraphemeBreakTest.txt')
EMOJI_DATA_TXT = data_path('emoji-data.txt')


class ParseFail(ValueError):
	pass


class GraphemeBreakProps:
    Control = None
    Prepend = None
    Extend = None
    SpacingMark = None
    L = None
    V = None
    LV = None
    LVT = None
    T = None
    RI = None
    ZWJ = None

    @classmethod
    def init(cls):
        cls.Control = set()
        cls.Prepend = set()
        cls.Extend = set()
        cls.SpacingMark = set()
        cls.L = set()
        cls.V = set()
        cls.LV = set()
        cls.LVT = set()
        cls.RI = set()
        cls.T = set()
        cls.ZWJ = set()


def load_grapheme_break_props(path=GRAPHEME_BREAK_PROPRETY_TXT):
    GraphemeBreakProps.init()
    with open(path, 'r') as f:
        while True:
            s = read_data_line(f)
            if s == '':
                break

            rng, prop = parse_unicode_range_prop(s)
            if prop == 'Control':
                add_range(GraphemeBreakProps.Control, rng)
            elif prop == 'Prepend':
                add_range(GraphemeBreakProps.Prepend, rng)
            elif prop == 'Extend':
                add_range(GraphemeBreakProps.Extend, rng)
            elif prop == 'SpacingMark':
                add_range(GraphemeBreakProps.SpacingMark, rng)
            elif prop == 'L':
                add_range(GraphemeBreakProps.L, rng)
            elif prop == 'V':
                add_range(GraphemeBreakProps.V, rng)
            elif prop == 'LV':
                add_range(GraphemeBreakProps.LV, rng)
            elif prop == 'LVT':
                add_range(GraphemeBreakProps.LVT, rng)
            elif prop == 'Regional_Indicator':
                add_range(GraphemeBreakProps.RI, rng)
            elif prop == 'T':
                add_range(GraphemeBreakProps.T, rng)
            elif prop == 'ZWJ':
                add_range(GraphemeBreakProps.ZWJ, rng)


class EmojiProps:
    Emoji = None
    Emoji_Presentation = None
    Emoji_Modifier_Base = None
    Extended_Pictographic = None

    @classmethod
    def init(cls):
        cls.Emoji = set()
        cls.Emoji_Presentation = set()
        cls.Emoji_Modifier_Base = set()
        cls.Extended_Pictographic = set()


def load_emoji_props(path=EMOJI_DATA_TXT):
    EmojiProps.init()
    with open(path, 'r') as f:
        while True:
            s = read_data_line(f)
            if s == '':
                break

            rng, prop = parse_unicode_range_prop(s)
            if prop == 'Emoji':
                add_range(EmojiProps.Emoji, rng)
            elif prop == 'Emoji_Presentation':
                add_range(EmojiProps.Emoji_Presentation, rng)
            elif prop == 'Emoji_Modifier_Base':
                add_range(EmojiProps.Emoji_Modifier_Base, rng)
            elif prop == 'Extended_Pictographic':
                add_range(EmojiProps.Extended_Pictographic, rng)


class InCBProps:
    Linker = None
    Consonant = None
    Extend = None

    @classmethod
    def init(cls):
        cls.Linker = set()
        cls.Consonant = set()
        cls.Extend = set()


def load_incb_props(path=DERIVED_CORE_PROPERTIES_TXT):
    InCBProps.init()
    with open(path, 'r') as f:
        while True:
            s = read_data_line(f)
            if s == '':
                break

            rng, prop = parse_unicode_range_prop(s)
            if prop == 'InCB=Linker':
                add_range(InCBProps.Linker, rng)
            elif prop == 'InCB=Consonant':
                add_range(InCBProps.Consonant, rng)
            elif prop == 'InCB=Extend':
                add_range(InCBProps.Extend, rng)


def parse_unicode_range_prop(s):
    rng_proprest = s.split(';')
    if len(rng_proprest) < 2:
        raise ParseFail(s)

    rng = rng_proprest[0]
    proprest = '='.join(el.strip() for el in rng_proprest[1:])

    rng = rng.strip()
    first, last = parse_range(rng)
    prop_rest = proprest.split('#')

    if len(prop_rest) < 2:
        raise ParseFail(s)

    prop, _ = prop_rest[:2]
    prop = prop.strip()
    return (first, last), prop


def read_data_line(f):
    while True:
        s = f.readline()
        if s == '':
            return ''
        if s[0] == '#' or s[0] == '\n':
            continue
        return s


def parse_range(rng):
	if rng.find('..') > -1:
		first, last = rng.split('..')
	else:
		first = last = rng
	return (int(first, 16), int(last, 16))


def add_range(s, rng):
    s |= set(range(rng[0], rng[1] + 1))
    return s


def set_stats(s):
    rng = max(s) - min(s) + 1
    l = len(s)
    return l, l / rng, min(s), max(s)


def load_grapheme_break_test(path=GRAPHEME_BREAK_TEST_TXT):
    test_cases = []
    with open(path, 'r') as f:
        while True:
            s = read_data_line(f)
            if s == '':
                break
            test_cases.append(parse_grapheme_break_test_line(s))
    return test_cases


def parse_grapheme_break_test_line(s):
    comstart = s.find('#')
    if comstart > -1:
        s = s[:comstart]

    elements = s.split()
    if elements[0] != '\u00f7':
        raise ParseFail(s)
    ustr = ''
    breaks = []
    if len(elements) % 2 != 1:
        raise ParseFail(s)
    for i in range(1, len(elements), 2):
        cp = int(elements[i], 16)
        ustr += chr(cp)
        brk_chr = elements[i + 1]
        if brk_chr != '\u00f7' and brk_chr != '\u00d7':
            raise ParseFail(s)
        if brk_chr == '\u00d7':
            continue
        breaks.append(i // 2)
    return ustr, breaks
