# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
import pytest

from ugrapheme import graphemes
from ugrapheme_diag.pystring_info import (is_ascii, is_latin1,
                                          is_2byte_unicode, is_4byte_unicode)


class TestConstruct:
    def test_empty(self):
        g = graphemes('')
        assert g == ''
        assert str(g) == ''
        assert len(g) == 0
        assert list(g) == []
        assert list(reversed(g)) == []
        assert list(g.offsets_iter()) == [0]
        assert g == graphemes('')
        assert g[:] == ''
        assert g[:-1] == ''
        assert g[1:1] == ''
        assert g[-1:1] == ''
        assert g[::-1] == ''
        assert g[::2] == ''
        assert g[::-2] == ''
        assert g.gslice() == graphemes('')
        assert g.gslice(end=-1) == ''
        assert g.gslice(start=1, end=1) == ''
        assert g.gslice(start=-1, end=1) == ''
        assert g.gslice(step=-1) == ''
        assert g.gslice(step=2) == ''
        assert g.gslice(step=-2) == ''
        assert g.endswith('')
        assert g.startswith('')
        assert g.find('') == 0
        assert g.rfind('') == 0
        assert g.index('') == 0
        assert '' in g
        assert g.ljust(5, 'x') == 'xxxxx'
        assert g.rjust(5, 'x') == 'xxxxx'
        assert g.center(5, 'x') == 'xxxxx'
        with pytest.raises(ValueError):
            min(g)
        with pytest.raises(IndexError):
            g[0]
        with pytest.raises(IndexError):
            g.at(0)
        assert g.off_at(0) == 0
        assert g.off_to_pos(0) == 0
        g2 = graphemes(g)
        assert g2 == g
        assert list(g2.offsets_iter()) == list(g.offsets_iter())

    def test_hello(self):
        g = graphemes('hello')
        assert g == 'hello'
        assert str(g) == 'hello'
        assert len(g) == 5
        assert list(g) == ['h', 'e', 'l', 'l', 'o']
        assert list(reversed(g)) == ['o', 'l', 'l', 'e', 'h']
        assert list(g.offsets_iter()) == [0, 1, 2, 3, 4, 5]
        assert g == graphemes('hello')
        assert g[:] == 'hello'
        assert g[:-2] == 'hel'
        assert g[3:] == 'lo'
        assert g[::-1] == 'olleh'
        assert g[-3::-1] == 'leh'
        assert g[::2] == 'hlo'
        assert g[::-2] == 'olh'
        assert g.startswith('he')
        assert g.endswith('llo')
        assert g.find('l') == 2
        assert g.rfind('l') == 3
        assert g.count('l') == 2
        assert g.index('o') == 4
        assert 'h' in g
        assert g.rjust(7, 'x') == 'xxhello'
        assert g.ljust(7, 'x') == 'helloxx'
        assert g.center(7, 'x') == 'xhellox'
        assert min(g) == 'e'
        assert max(g) == 'o'
        assert g[0] == 'h'
        assert g[-1] == 'o'
        assert g.off_at(4) == 4
        assert g.off_to_pos(4) == 4

    def test_number(self):
        assert graphemes(5.23) == '5.23'

    def test_graphemes(self):
        g = graphemes('hello')
        g2 = graphemes(g)
        assert g2 == 'hello'


class TestExamples:
    def test_scientist_flag(self):
        scientist = '👩🏽‍🔬'
        flag = '🏴󠁧󠁢󠁳󠁣󠁴󠁿'
        g = graphemes(scientist + flag + 'Hi')
        assert len(g) == 4
        assert g[0] == scientist
        assert g[1] == flag
        assert g[2] == 'H'
        assert g[3] == 'i'
        with pytest.raises(IndexError):
            g[4]
        assert g[-1] == 'i'
        assert g[-2] == 'H'
        assert g[-3] == flag
        assert g[-4] == scientist
        with pytest.raises(IndexError):
            g[-5]
        assert list(g) == [scientist, flag, 'H', 'i']
        assert list(reversed(g)) == ['i', 'H', flag, scientist]
        assert list(g.offsets_iter()) == [
                0, len(scientist), len(scientist) + len(flag),
                len(scientist) + len(flag) + 1,
                len(scientist) + len(flag) + 2]
        assert g[2:] == 'Hi'
        assert g[:2] == scientist + flag
        assert g[::-1] == 'iH' + flag + scientist
        assert g[::2] == scientist + 'H'
        assert g[1::2] == flag + 'i'
        assert g[::-2] == 'i' + flag
        assert g[-2::-2] == 'H' + scientist
        assert flag in g
        assert '🔬' not in g
        assert not g.has('🔬')
        assert g.has('🔬', partial=True)
        assert g.find('🔬') == -1
        assert g.find('🔬', partial=True) == 0
        assert g.find('🏴') == -1
        assert g.find('🏴', partial=True) == 1
        assert g.count('🔬') == 0
        assert g.count(scientist) == 1
        assert g.count(flag) == 1
        assert g.count(scientist + flag) == 1
        assert g.count('Hi') == 1
        with pytest.raises(ValueError):
                g.index('🔬')
        assert g.index('🔬', partial=True) == 0
        assert max(g) == scientist
        assert min(g) == 'H'
        assert ','.join(g) == scientist + ',' + flag + ',H,i'
        assert graphemes('').join(g) == g
        assert len(graphemes('').join(g)) == len(g)
        assert list(graphemes('').join(g)) == list(g)
        assert graphemes(',').join(g) == scientist + ',' + flag + ',H,i'
        assert g.ljust(8, '-') == scientist + flag + 'Hi--'
        assert g.rjust(8, '-') == '--' + scientist + flag + 'Hi'
        assert g.center(8, '-') == '-' + scientist + flag + 'Hi-'

    def test_like_this(self):
        # https://users.rust-lang.org/t/how-to-work-with-strings-and-graphemes-similar-to-sql-how-to-avoid-crate-proliferation/55349/21?page=2
        # ...But if you can get it to work with unicode text like this
        # you will be way ahead of the game.
        like_this = graphemes('l̷̢̢̰̬͇̙͉͕̠̠̥̂̿̋͑̕͝͠ͅͅĩ̴̡̢̛̠̻̫̲͉̤̱̟͍̤̳͔͐̍̔̈́͊̒͂͋̈́̉̔̕̚͜͜͠k̸͍̳̜̗̰̼̦̟̖̳̥̙̗̂́̓̎͌͊͘ȩ̴͔̝̤̳̖̜̓̽̕ ̶̪̺͖̈́̃t̷̪̯̟̳͍̲͔̎͋̿̉̒̑̓̊̾̊̒̚͘ḩ̷̦͂̈́͗͌̏̏̇̔̈́͒̒̆̄̈́̚͠į̸̨̡̛̤͚͓̯͎̘̪̙̟̮͈͔͔̈́͋̉̾̃̎̒̈́́̾͂́ͅś̷̘̙̜̯͖̄͆̿̄̑̄̄͝')

        assert len(like_this) == 9
        like = 'l̷̢̢̰̬͇̙͉͕̠̠̥̂̿̋͑̕͝͠ͅͅĩ̴̡̢̛̠̻̫̲͉̤̱̟͍̤̳͔͐̍̔̈́͊̒͂͋̈́̉̔̕̚͜͜͠k̸͍̳̜̗̰̼̦̟̖̳̥̙̗̂́̓̎͌͊͘ȩ̴͔̝̤̳̖̜̓̽̕'
        this = 't̷̪̯̟̳͍̲͔̎͋̿̉̒̑̓̊̾̊̒̚͘ḩ̷̦͂̈́͗͌̏̏̇̔̈́͒̒̆̄̈́̚͠į̸̨̡̛̤͚͓̯͎̘̪̙̟̮͈͔͔̈́͋̉̾̃̎̒̈́́̾͂́ͅś̷̘̙̜̯͖̄͆̿̄̑̄̄͝'
        assert len(graphemes(like)) == 4
        assert len(graphemes(this)) == 4
        assert like_this[:4] == like
        assert like_this[5:] == this
        assert len(like_this.gslice(end=4)) == 4
        assert len(like_this.gslice(start=5)) == 4

        siht_ekil = graphemes('ś̷̘̙̜̯͖̄͆̿̄̑̄̄͝į̸̨̡̛̤͚͓̯͎̘̪̙̟̮͈͔͔̈́͋̉̾̃̎̒̈́́̾͂́ͅḩ̷̦͂̈́͗͌̏̏̇̔̈́͒̒̆̄̈́̚͠t̷̪̯̟̳͍̲͔̎͋̿̉̒̑̓̊̾̊̒̚͘ ̶̪̺͖̈́̃ȩ̴͔̝̤̳̖̜̓̽̕k̸͍̳̜̗̰̼̦̟̖̳̥̙̗̂́̓̎͌͊͘ĩ̴̡̢̛̠̻̫̲͉̤̱̟͍̤̳͔͐̍̔̈́͊̒͂͋̈́̉̔̕̚͜͜͠l̷̢̢̰̬͇̙͉͕̠̠̥̂̿̋͑̕͝͠ͅͅ')
        assert siht_ekil[::-1] == like_this
        ekil = graphemes(like)[::-1]
        siht = graphemes(this)[::-1]
        assert ekil == siht_ekil[5:]
        assert siht == siht_ekil[:4]
        assert like_this.gslice(end=4) == like
        assert like_this.gslice(end=4)[::-1] == siht_ekil[5:]

        assert ' ' not in like_this
        assert like_this.has(' ', partial=True)
        assert like_this.find(' ', partial=True) == 4

    def test_underlined(self):
        # https://github.com/alvinlindstam/grapheme
        g = graphemes('u̲n̲d̲e̲r̲l̲i̲n̲e̲d̲')
        assert len(g) == 10
        assert g[:5] == 'u̲n̲d̲e̲r̲'
        assert g[5:] == 'l̲i̲n̲e̲d̲'
        assert g[::-1] == 'd̲e̲n̲i̲l̲r̲e̲d̲n̲u̲'
        assert 'u' not in g
        assert 'u̲' in g
        assert g.has('u', partial=True)
        assert 'e' not in g
        assert 'e̲' in g
        assert g[3] == 'e̲'
        assert g.find('e̲') == 3
        assert g.find('e') == -1
        assert g.find('e', partial=True) == 3
        assert g[8] == 'e̲'
        assert g.rfind('e̲') == 8
        assert g.rfind('e') == -1
        assert g.rfind('e', partial=True) == 8
        assert g.count('e̲') == 2
        assert g.count('e') == 0
        assert g.gslice(end=5) == 'u̲n̲d̲e̲r̲'
        assert g.gslice(start=5) == 'l̲i̲n̲e̲d̲'
        assert g.gslice(step=-1) == 'd̲e̲n̲i̲l̲r̲e̲d̲n̲u̲'
        assert len(g.gslice(end=5)) == 5
        assert len(g.gslice(start=5)) == 5
        assert len(g.gslice(step=-1)) == 10

    def test_pyuegc_korean(self):
        # https://github.com/mlodewijck/pyuegc
        g = graphemes('기운찰만하다')
        assert len(g) == 6
        assert list(g) == ['기', '운', '찰', '만', '하', '다']

    def test_pyuegc_bengali(self):
        # https://github.com/mlodewijck/pyuegc
        g = graphemes('পৌষসংক্রান্তির')
        assert len(g) == 6
        assert list(g) == ['পৌ', 'ষ', 'সং', 'ক্রা', 'ন্তি', 'র']

    def test_pyuegc_ainee(self):
        # https://github.com/mlodewijck/pyuegc
        g = graphemes("ai\u0302ne\u0301e")
        assert len(g) == 5
        assert g[::-1] == 'eénîa'

    def test_devanagari_coach_gun(self):
        # https://stackoverflow.com/questions/78102711/get-python-characters-from-asian-text
        g = graphemes('बन्दूक')
        assert len(g) == 3
        assert list(g) == ['ब', 'न्दू', 'क']

    def test_devanagari_coach_gun_2x(self):
        # https://stackoverflow.com/questions/78102711/get-python-characters-from-asian-text#comment137939643_78113676
        g = graphemes("बन्दूक बन्दूक")
        assert len(g) == 7
        assert list(g) == ['ब', 'न्दू', 'क', ' ', 'ब', 'न्दू', 'क']

    def test_devanagari_hindi_andjc(self):
        # https://gist.github.com/andjc/43a98c6d6f5e419303604081d57a401e
        g = graphemes("हिन्दी")
        assert len(g) == 2
        assert list(g) == ['हि', 'न्दी']

    def test_devanagari_namaste(self):
        g = graphemes("नमस्ते")
        assert len(g) == 3
        assert list(g) == ['न', 'म', 'स्ते']

    def test_devanagari_bi_tri_tetra_conjucts(self):
        # https://stackoverflow.com/questions/75210512/how-to-split-devanagari-bi-tri-and-tetra-conjunct-consonants-as-a-whole-from-a-s
        g = graphemes("हिन्दी मुख्यमंत्री हिमंत")
        assert list(g) == ['हि', 'न्दी',
                           ' ',
                           'मु', 'ख्य', 'मं', 'त्री',
                           ' ',
                           'हि', 'मं', 'त']

    def test_tamil(self):
        # https://stackoverflow.com/questions/33068727/how-to-split-unicode-strings-character-by-character-in-python
        g = graphemes("தமிழ்")
        assert len(g) == 3
        assert list(g) == ['த', 'மி', 'ழ்']


class TestConcatenation:
    def test_empty(self):
        g = graphemes('') + ''
        assert g == ''
        assert g == graphemes('')
        assert len(g) == 0
        assert list(g) == []
        assert list(g.offsets_iter()) == [0]
        assert g.off_at(0) == 0
        assert g.off_to_pos(0) == 0

        g2 = '' + graphemes('')
        assert g2 == g
        assert list(g2) == list(g)
        assert list(g2.offsets_iter()) == list(g.offsets_iter())

        g3 = g + g2
        assert g3 == g2
        assert list(g3) == list(g2)
        assert list(g3.offsets_iter()) == list(g2.offsets_iter())

        assert graphemes('hello') + '' == graphemes('hello')
        assert graphemes('') + graphemes('hello') == graphemes('hello')
        assert graphemes('') + 'hello' == graphemes('hello')
        assert graphemes('') + 'hello' == 'hello'
        assert isinstance(graphemes('') + 'hello', graphemes)
        assert isinstance(graphemes('hello') + '', graphemes)

    def test_simple_ascii(self):
        g = 'hello' + graphemes(' ') + 'there'
        assert isinstance(g, graphemes)
        assert g == 'hello there'
        assert list(g) == list('hello there')
        assert list(g.offsets_iter()) == list(
            graphemes('hello there').offsets_iter())

    def test_ascii_cr_lf_1(self):
        assert len(graphemes('\u000d')) == 1
        assert len(graphemes('\u000a')) == 1
        assert len(graphemes('\u000d\u000a')) == 1
        g1 = graphemes('hello\u000d')
        g2 = graphemes('\u000athere')
        assert len(g1) == 6
        assert len(g2) == 6
        assert g1 + g2 == 'hello\u000d\u000athere'
        assert len(g1 + g2) == 11
        assert list((g1 + g2).offsets_iter()) == [
            0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12]

        assert len(graphemes('hello\u000d') + '\u000athere') == 11
        assert len('hello\u000d' + graphemes('\u000athere')) == 11
        assert len('\u000athere' + graphemes('hello\u000d')) == 12
        assert len(graphemes('hello\u000a') + '\u000dthere') == 12

    def test_ascii_cr_lf_2(self):
        assert len(graphemes('hello') + '\u000d\u000a') == 6
        assert len('hello' + graphemes('\u000d') + '\u000a') == 6
        assert len('hello' + graphemes('\u000a') + '\u000d') == 7
        assert len(graphemes('hello') + '\u000d') == 6

    def test_inplace_add_empty(self):
        s = 'hello'
        assert isinstance(s, str)
        assert is_ascii(s)
        s += graphemes('')
        assert isinstance(s, graphemes)
        assert len(s) == 5
        assert is_ascii(s)
        s += ''
        assert isinstance(s, graphemes)
        assert len(s) == 5
        assert is_ascii(s)

    def test_inplace_add_simple(self):
        s = 'hello'
        assert isinstance(s, str)
        s += graphemes(' ')
        assert isinstance(s, graphemes)
        s += 'there'
        assert isinstance(s, graphemes)
        assert s == 'hello there'
        assert list(s) == list('hello there')
        assert is_ascii(s)

    def test_inplace_add_crlf(self):
        g = graphemes('hello')
        assert len(g) == 5
        g += '\u000d'
        assert isinstance(g, graphemes)
        assert g[-1] == '\u000d'
        assert g[5] == '\u000d'
        assert len(g) == 6
        g += '\u000a'
        assert g[-1] == '\u000d\u000a'
        assert g[5] == '\u000d\u000a'
        assert len(g) == 6
        g += 'there'
        assert g[6] == 't'
        assert g.off_at(5) == 5
        assert g.off_at(6) == 7
        assert len(g) == 11
        assert g == 'hello\u000d\u000athere'
        assert list(g.offsets_iter()) == [
            0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12]

    def test_add_multiscript(self):
        scientist = '👩🏽‍🔬'
        flag = '🏴󠁧󠁢󠁳󠁣󠁴󠁿'
        assert len(graphemes(scientist)) == 1
        assert len(graphemes(flag)) == 1
        g = graphemes('hello') + graphemes(scientist) + graphemes(flag)
        assert len(g) == 7
        assert (list(g.offsets_iter())
            == list(graphemes('hello' + scientist + flag).offsets_iter()))
        assert len(graphemes('hello') + scientist + flag) == 7
        assert len('hello' + scientist + graphemes(flag)) == 7
        namaste = graphemes("नमस्ते")
        assert len(namaste) == 3
        assert len(g + namaste) == 10
        assert len(g + str(namaste)) == 10
        assert len(str(g) + namaste) == 10

    def test_add_decomposed_accents(self):
        g = "ai" + graphemes("\u0302") + graphemes("ne") + "\u0301e"
        assert g == 'aînée'
        assert len(g) == 5
        assert is_2byte_unicode(g)

    def test_inplace_add_decomposed_accents(self):
        g = graphemes("ai")
        assert len(g) == 2
        assert g[-1] == 'i'
        assert is_ascii(g)

        g += "\u0302"
        assert len(g) == 2
        assert g[-1] == 'î'
        assert is_2byte_unicode(g)

        g += "ne"
        assert len(g) == 4
        assert g == "aîne"
        assert g[-1] == 'e'
        g += "\u0301e"
        assert len(g) == 5
        assert g[-2] == 'é'
        assert g[-1] == 'e'
        assert g == 'aînée'
        assert is_2byte_unicode(g)

    def test_add_incomplete_graphemes(self):
        scientist = '👩🏽‍🔬'
        flag = '🏴󠁧󠁢󠁳󠁣󠁴󠁿'
        sci1 = scientist[:2]
        sci2 = scientist[2:]
        flag1 = flag[:2]
        flag2 = flag[2:]
        assert len(sci1 + graphemes(sci2)) == 1
        assert sci1 + graphemes(sci2) == graphemes(scientist)
        assert len(graphemes(flag1) + flag2) == 1
        assert graphemes(flag1) + flag2 == flag
        assert len(sci1 + graphemes(sci2 + flag1) + flag2) == 2
        assert sci1 + graphemes(sci2 + flag1) + flag2 == scientist + flag
        assert (sci1 + graphemes(sci2 + flag1) + flag2)[-1] == flag
        assert (sci1 + graphemes(sci2 + flag1) + flag2)[0] == scientist

    def test_inplace_add_incomplete_graphemes(self):
        scientist = '👩🏽‍🔬'
        flag = '🏴󠁧󠁢󠁳󠁣󠁴󠁿'

        sci1 = scientist[:2]
        sci2 = scientist[2:]
        flag1 = flag[:2]
        flag2 = flag[2:]

        out = graphemes(sci1)
        out += sci2
        assert len(out) == 1
        assert out == scientist
        out += flag1
        out += graphemes(flag2)
        assert len(out) == 2
        assert out[1] == flag
        assert out == scientist + flag

        out2 = sci1
        out2 += graphemes(sci2 + flag1)
        out2 += flag2
        assert len(out) == 2
        assert out[1] == flag
        assert out[0] == scientist


class TestReplication:
    def test_replicate_zero(self):
        assert graphemes('') * 0 == ''
        assert isinstance(graphemes('') * 0, graphemes)
        assert list((graphemes('') * 0).offsets_iter()) == [0]

        assert graphemes('hello') * 0 == ''
        assert isinstance(graphemes('hello') * 0, graphemes)
        assert len(graphemes('hello') * 0) == 0

    def test_replicate_identity(self):
        assert graphemes('hello') * 1 == 'hello'
        assert isinstance(graphemes('hello') * 1, graphemes)

        assert len(graphemes('hello\u000d\u000a') * 1) == 6
        assert (graphemes('hello\u000d\u000a') * 1)[-1] == '\u000d\u000a'

        scientist = '👩🏽‍🔬'
        flag = '🏴󠁧󠁢󠁳󠁣󠁴󠁿'
        assert len(graphemes(scientist + flag + 'Hi') * 1) == 4

    def test_simple_replicate(self):
        assert graphemes('hello') * 2 == 'hellohello'
        assert len(graphemes('hi\r\n') * 10) == len(graphemes('hi\r\n' * 10))
        scientist = '👩🏽‍🔬'
        flag = '🏴󠁧󠁢󠁳󠁣󠁴󠁿'
        assert graphemes(scientist + flag) * 2 == graphemes(
            (scientist + flag) * 2)
        assert len(graphemes(scientist + flag)) == 2
        assert len(graphemes(scientist + flag) * 10) == 20

    def test_difficult_replicate(self):
        assert len(graphemes('\u000ahello\u000d')) == 7
        assert graphemes('\u000ahello\u000d') * 2 == graphemes(
            '\u000ahello\u000d\u000ahello\u000d')
        assert len(graphemes('\u000ahello\u000d') * 2) == 13
        assert len(graphemes('\u000ahello\u000d') * 3) == 19

        scientist = '👩🏽‍🔬'
        sci1 = scientist[:2]
        sci2 = scientist[2:]

        assert len(graphemes(scientist)) == 1
        assert graphemes(sci2 + sci1) * 2 == graphemes(
            sci2 + scientist + sci1)
        assert graphemes(sci2 + sci1) * 10 == graphemes(
            sci2 + scientist * 9 + sci1)
        assert len(graphemes(sci2 + sci1) * 10) == len(graphemes(
            sci2 + scientist * 9 + sci1))
        assert len(graphemes(sci2 + sci1) * 10) == (
            len(graphemes(sci2)) + 9 + len(graphemes(sci1)))
        assert (graphemes(sci2 + sci1) * 10)[
            len(graphemes(sci2))] == scientist


class TestJoin:
    def test_join_empty(self):
        assert graphemes('').join([]) == ''
        assert len(graphemes('stuff').join([])) == 0
        assert list(graphemes('').join([]).offsets_iter()) == [0]

    def test_join_strings(self):
        assert graphemes('').join(['hey', 'hi', 'there']) == 'heyhithere'
        assert graphemes(',').join(['hey', 'hi', 'there']) == 'hey,hi,there'
        assert graphemes(',').join(['hey']) == 'hey'
        assert isinstance(graphemes(',').join(['hey']), graphemes)

        assert graphemes('').join(list('hey')) == 'hey'
        assert graphemes('😊🥹').join(list('hey')) == 'h😊🥹e😊🥹y'

        assert graphemes('').join(['', '', '', '']) == ''

        scientist = '👩🏽‍🔬'
        flag = '🏴󠁧󠁢󠁳󠁣󠁴󠁿'
        assert graphemes(',').join([scientist, flag, 'Hi']) == ','.join(
            [scientist, flag, 'Hi'])

        assert (graphemes(flag).join(['a','b','c'])
                == 'a' + flag + 'b' + flag + 'c')
        assert len(graphemes(flag).join(['a','b','c'])) == 5

    def test_join_strings_or_graphemes(self):
        assert graphemes(',').join(
            ['hey', graphemes('hi'), 'there']) == 'hey,hi,there'
        scientist = '👩🏽‍🔬'
        flag = '🏴󠁧󠁢󠁳󠁣󠁴󠁿'
        assert (len(graphemes('').join([graphemes(scientist), flag, 'Hi']))
                == 4)
        assert len(graphemes(',').join([
            graphemes(scientist), graphemes(flag), graphemes('Hi')])) == 6

    def test_join_difficult(self):
        assert len(graphemes('').join(['hello', '\u000d'])) == 6
        assert len(graphemes('').join(['hello', '\u000d', '\u000a'])) == 6
        assert len(graphemes('\u000d').join(['hello', '\u000a'])) == 6
        assert graphemes('\u0301').join(['e','x']) == 'éx'
        assert len(graphemes('\u0301').join(['e','x'])) == 2
        assert len(graphemes('\u0301').join(['e',graphemes('x')])) == 2

        scientist = '👩🏽‍🔬'
        flag = '🏴󠁧󠁢󠁳󠁣󠁴󠁿'

        sci1 = scientist[:2]
        sci2 = scientist[2:]
        flag1 = flag[:2]
        flag2 = flag[2:]
        assert (graphemes('').join([sci1, sci2, flag1, flag2])
                == scientist + flag)
        assert len(graphemes('').join([sci1, sci2, flag1, flag2])) == 2
        assert len(graphemes('').join(
            [sci1, sci2, graphemes(flag1), flag2])) == 2
        assert len(graphemes('').join(
            [graphemes(sci1), graphemes(sci2),
             graphemes(flag1), graphemes(flag2)])) == 2
        assert len(graphemes('').join(
            [graphemes(sci1), '', '', graphemes(sci2),
             graphemes(flag1), '', graphemes(flag2), '', ''])) == 2


class TestSlicing:
    def test_basic_indexing_and_slices(self):
        g = graphemes('hello\u000d\u000athere')
        assert g[0] == 'h'
        assert g[4] == 'o'
        assert g[5] == '\u000d\u000a'
        assert g[6] == 't'
        assert g[10] == 'e'

        assert len(g) == 11

        with pytest.raises(IndexError):
            g[11]

        assert g[-11] == g[0]

        with pytest.raises(IndexError):
            g[-12]

        assert g[-1] == 'e'
        assert g[-5] == 't'
        assert g[-6] == '\u000d\u000a'

        assert g[:] == g
        assert g[:5] == 'hello'
        assert g[6:] == 'there'

        assert g[:5:2] == 'hlo'
        assert g[1:5:2] == 'el'
        assert g[:5:-1] == 'ereht'
        assert g[:5:-2] == 'eet'
        assert g[-2:5:-2] == 'rh'

        assert g[:100] == g
        assert g[-100:] == g
        assert g[-100:100] == g
        assert g[-100:100:2] == g[::2]
        assert g[100:-100:-1] == g[::-1]
        assert g[100:-100:-2] == g[::-2]

        assert g[-100:5] == 'hello'
        assert g[6:100] == 'there'
        assert g[-100:-90] == ''
        assert g[-len(g):] == g
        assert g[90:100] == ''
        assert g[-len(g):-1] == g[:-1]
        assert len(g[:-1]) == len(g[:]) - 1

    def test_type_downcasts(self):
        gscientist = graphemes('👩🏽‍🔬')
        gflag = graphemes('🏴󠁧󠁢󠁳󠁣󠁴󠁿')
        ghello = graphemes('hello')
        gmueller = graphemes('müller')
        gnamaste = graphemes("नमस्ते")

        g = gscientist + gflag + ghello + gmueller + gnamaste
        assert is_4byte_unicode(g)

        assert is_4byte_unicode(g[:7])
        assert g[2:7] == 'hello'
        assert is_ascii(g[2:7])
        assert is_ascii(g[6:1:-1])

        assert g[7:13] == 'müller'
        assert is_latin1(g[7:13])
        assert is_latin1(g[12:6:-1])

        assert g[2:13] == 'hellomüller'
        assert is_latin1(g[2:13])
        assert is_latin1(g[12:1:-1])

        assert g[7:13:2] == 'mle'
        assert is_ascii(g[7:13:2])
        assert is_ascii(g[11:6:-2])

        assert g[7:16] == 'müllerनमस्ते'
        assert is_2byte_unicode(g[7:16])
        assert is_2byte_unicode(g[15:6:-1])

        assert g[13:] == 'नमस्ते'
        assert is_2byte_unicode(g[13:])
        assert is_2byte_unicode(g[:12:-1])

    def test_grapheme_reverse(self):
        gscientist = graphemes('👩🏽‍🔬')
        gflag = graphemes('🏴󠁧󠁢󠁳󠁣󠁴󠁿')

        assert gscientist[::-1] == gscientist
        assert gflag[::-1] == gflag

        ghello = graphemes('hello')
        gmueller = graphemes('müller')
        gnamaste = graphemes("नमस्ते")

        assert is_ascii(ghello)
        assert is_latin1(gmueller)
        assert is_2byte_unicode(gnamaste)

        g = graphemes('').join([gscientist, gflag,
                                ghello, gmueller, gnamaste])
        assert g[::-1] == 'स्तेमनrellümolleh🏴󠁧󠁢󠁳󠁣󠁴󠁿👩🏽‍🔬'
        assert g[::-1] == (gnamaste[::-1] + gmueller[::-1] + ghello[::-1]
                           + gflag[::-1] + gscientist[::-1])

    def test_gslice(self):
        g = graphemes('hello\u000d\u000athere')

        assert g.gslice() == g
        assert g.gslice(end=5) == 'hello'
        assert g.gslice(start=6) == 'there'

        assert g.gslice(end=5, step=2) == 'hlo'
        assert g.gslice(start=1, end=5, step=2) == 'el'
        assert g.gslice(end=5, step=-1) == 'ereht'
        assert g.gslice(end=5, step=-2) == 'eet'
        assert g.gslice(start=-2, end=5, step=-2) == 'rh'

        assert g.gslice(end=100) == g
        assert g.gslice(start=-100) == g
        assert g.gslice(start=-100, end=100) == g
        assert g.gslice(start=-100, end=100, step=2) == g[::2]
        assert g.gslice(start=100, end=-100, step=-1) == g[::-1]
        assert g.gslice(start=100, end=-100, step=-2) == g[::-2]

        assert g.gslice(-100, end=5) == 'hello'
        assert g.gslice(start=6, end=100) == 'there'
        assert g.gslice(start=-100, end=-90) == ''
        assert g.gslice(start=-len(g)) == g
        assert g.gslice(start=90, end=100) == ''
        assert g.gslice(start=-len(g), end=-1) == g[:-1]
        assert len(g.gslice(end=-1)) == len(g) - 1


class TestSearch:
    def test_simple_searches(self):
        g = graphemes("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")
        assert g.find("Hello") == 0
        assert g.find("👩🏽‍🔬!") == 6
        assert g.find("👩🏼‍❤️‍💋‍👨🏾") == 9
        assert g.find("अनुच्छेद") == 11

        assert g.find("l") == 2
        assert g.rfind("l") == 3
        assert g.index("l") == 2
        assert g.rindex("l") == 3

        assert g.rfind(" ") == 10
        assert g.rindex(" ") == 10

        assert g.count("l") == 2
        assert g.count(" ") == 3

        assert g.find("x") == -1
        assert g.rfind("x") == -1

        with pytest.raises(ValueError):
            g.index("x")

        with pytest.raises(ValueError):
            g.rindex("x")

        assert g.startswith("Hel")
        assert not g.startswith('a')
        assert g.endswith("च्छेद")
        assert not g.endswith('b')

    def test_empty(self):
        g = graphemes('')

        assert g.find('') == 0
        assert g.rfind('') == 0
        assert g.count('') == 1
        assert g.index('') == 0
        assert g.rindex('') == 0
        assert g.find('a') == -1
        assert g.rfind('a') == -1

        with pytest.raises(ValueError):
            g.index('a')

        with pytest.raises(ValueError):
            g.rindex('a')

        assert g.startswith('')
        assert g.endswith('')

    def test_empty_sub(self):
        g = graphemes('hello')

        assert g.find('') == 0
        assert g.index('') == 0
        assert g.rfind('') == 5
        assert g.rindex('') == 5
        assert g.count('') == 6

        g2 = graphemes("👩🏽‍🔬")

        assert g2.rfind('') == 1
        assert g2.rindex('') == 1
        assert g2.count('') == 2

    def test_partial(self):
        g = graphemes("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")
        assert g.count('👩') == 0
        assert g.find('👩') == -1
        assert g.rfind('👩') == -1

        with pytest.raises(ValueError):
            g.index('👩')

        with pytest.raises(ValueError):
            g.rindex('👩')

        assert g.count('👩', partial=True) == 2
        assert g.find('👩', partial=True) == 6
        assert g.index('👩', partial=True) == 6
        assert g.rfind('👩', partial=True) == 9
        assert g.rindex('👩', partial=True) == 9

        assert not g.startswith('Hello 👩')
        assert g.startswith('Hello 👩', partial=True)
        assert not g.endswith('👨🏾 अनुच्छेद')
        assert g.endswith('👨🏾 अनुच्छेद', partial=True)

    def test_startswith_endswith_tuples(self):
        g = graphemes("Hello\r\nthere")

        assert not g.startswith("hello")
        assert g.startswith("Hello")
        assert g.startswith(("hello", "Hello"))

        assert g.endswith("there")
        assert g.endswith(("there",))
        assert not g.endswith("There")
        assert not g.endswith(("There",))
        assert g.endswith(("There", "there"))

        assert not g.startswith("Hello\u000d")
        assert g.startswith("Hello\u000d\u000a")
        assert g.startswith(("Hello\u000d", "Hello\u000d\u000a"))
        assert not g.endswith("\u000athere")
        assert not g.endswith(("\u000athere",))
        assert g.endswith("\u000d\u000athere")
        assert g.endswith(("\u000d\u000athere",))
        assert g.endswith(("\u000athere", "\u000d\u000athere"))

    def test_start_end_changed(self):
        g = graphemes("Hello\r\nthere")
        assert g.startswith("lo", start=3)
        assert not g.startswith("Hello", end=4)
        assert g.endswith("Hello", end=5)
        assert g.endswith("the", end=-2)
        assert g.startswith("there", start=-5)

        assert g.count("e") == 3
        assert g.count("e", end=5) == 1
        assert g.count("e", start=5, end=5) == 0
        assert g.count("e", start=-5) == 2
        assert g.count("e", start=-5, end=-2) == 1

        assert g.find("e", start=2) == 8
        assert g.find("e", start=8) == 8
        assert g.find("e", start=9) == 10

        assert g.rfind("e", end=-1) == 8
        assert g.rfind("e", end=-3) == 1


class TestReplace:
    def test_simple(self):
        g = graphemes("hello there")
        assert g.replace("e", "a") == "hallo thara"
        assert g.replace("XYZ", "a") == "hello there"
        assert g.replace("lo th", "") == "helere"
        assert g.replace("e", "") == "hllo thr"
        assert g.replace("ll", "<LL>") == "he<LL>o there"

        assert g.replace(graphemes("e"), graphemes("a")) == "hallo thara"

        assert g.replace("", "|") == "|h|e|l|l|o| |t|h|e|r|e|"

    def test_string_updowncast(self):
        g = graphemes("hello there")
        assert is_ascii(g)

        g = g.replace("o", "ö")
        assert g == "hellö there"
        assert is_latin1(g)

        g = g.replace("ö", "o")
        assert g == "hello there"
        assert is_ascii(g)

        g = g.replace("e", "é")
        assert g == "héllo théré"
        assert is_latin1(g)

        g = g.replace("é", "e")
        assert g == "hello there"
        assert is_ascii(g)

        gscientist = graphemes('👩🏽‍🔬')
        gflag = graphemes('🏴󠁧󠁢󠁳󠁣󠁴󠁿')
        ghello = graphemes('hello')
        gmueller = graphemes('müller')
        gnamaste = graphemes("नमस्ते")

        g = gscientist + gflag + ghello + gmueller + gnamaste
        g = g.replace(gscientist, "scientist")
        g = g.replace(gflag, "flag")
        assert g == "scientistflaghellomüllerनमस्ते"
        assert is_2byte_unicode(g)

        g = g.replace(gnamaste, "namaste")
        assert g == "scientistflaghellomüllernamaste"
        assert is_latin1(g)

        g = g.replace(gmueller, "mueller")
        assert g == "scientistflaghellomuellernamaste"
        assert is_ascii(g)

    def test_large_expand_contract(self):
        g = graphemes("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद") * 5
        gsub = graphemes("👩🏽‍🔬!")
        grepl = graphemes("🏴󠁧󠁢󠁳󠁣󠁴󠁿नमस्ते") * 20

        r = g.replace(gsub, grepl)
        assert r.count(graphemes("🏴󠁧󠁢󠁳󠁣󠁴󠁿नमस्ते")) == 20 * 5
        assert len(r) == len(g) + (len(grepl) - len(gsub)) * 5

        r = r.replace(grepl, gsub)
        assert r == g
        assert list(r.offsets_iter()) == list(g.offsets_iter())

        r = r.replace(graphemes("👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾"), "---")
        assert r.count("---") == 5
        assert is_2byte_unicode(r)

        r = r.replace(graphemes("अनुच्छेद"), graphemes("article"))
        assert r.count("article") == 5
        assert is_ascii(r)

    def test_difficult_1byte(self):
        g = graphemes("hi there\u000dsome more\u000dsome")
        assert len(g) == 23
        assert g[9] == 's'
        assert g[19] == 's'
        assert g[8] == '\u000d'
        assert g[18] == '\u000d'

        r = g.replace("some", "\u000asome")
        assert len(r) == 23
        assert r[9] == 's'
        assert r[19] == 's'
        assert r[8] == '\u000d\u000a'
        assert r[18] == '\u000d\u000a'

        r = g.replace("some", "\u000asome", 1)
        assert len(r) == 23
        assert r[8] == '\u000d\u000a'
        assert r[18] == '\u000d'

        r = g.replace("some", "\u000as")
        assert len(r) == 23 - (3 * 2)
        assert r[8] == '\u000d\u000a'
        assert r[10] == ' '
        assert r[18 - 3] == '\u000d\u000a'
        assert r[19 - 3] == 's'

        r = g.replace(graphemes("some"),
                      graphemes("\u000amuch much much longer"))
        assert len(r) == 23 + (len("much much much longer") - 4) * 2
        assert r[8] == '\u000d\u000a'
        assert r[18 + len("much much much longer") - 4] == '\u000d\u000a'

    def test_difficult_mbyte(self):
        g = graphemes("hi there\u000ds👩🏽‍🔬me more\u000ds👩🏽‍🔬me")
        assert len(g) == 23
        assert g[9] == 's'
        assert g[19] == 's'
        assert g[8] == '\u000d'
        assert g[18] == '\u000d'
        assert is_4byte_unicode(g)

        r = g.replace(graphemes("s👩🏽‍🔬me"), graphemes("\u000asöme"))
        assert len(r) == 23
        assert r[9] == 's'
        assert r[19] == 's'
        assert r[8] == '\u000d\u000a'
        assert r[18] == '\u000d\u000a'
        assert is_latin1(r)

        r = g.replace("s👩🏽‍🔬me", "\u000as")
        assert len(r) == 23 - (3 * 2)
        assert r[8] == '\u000d\u000a'
        assert r[10] == ' '
        assert r[18 - 3] == '\u000d\u000a'
        assert r[19 - 3] == 's'
        assert is_ascii(r)

        r = g.replace(graphemes("s👩🏽‍🔬me"),
                      graphemes("\u000amuch much much longer"))
        assert len(r) == 23 + (len("much much much longer") - 4) * 2
        assert r[8] == '\u000d\u000a'
        assert r[18 + len("much much much longer") - 4] == '\u000d\u000a'
        assert is_ascii(r)

    def test_blank(self):
        g = graphemes('')
        assert g.replace('', 'TEST') == 'TEST'
        assert g.replace('', '') == ''

        flag = '🏴󠁧󠁢󠁳󠁣󠁴󠁿'
        assert graphemes('hello').replace('', flag) == (
            flag + 'h' + flag + 'e' + flag + 'l' + flag + 'l' + flag + 'o'
            + flag)


class TestIter:
    def test_simple_iter(self):
        g = graphemes('hello\u000d\u000athere')
        assert list(g) == ['h', 'e', 'l', 'l', 'o', '\u000d\u000a',
                           't', 'h', 'e', 'r', 'e']

        assert list(reversed(g)) == ['e', 'r', 'e', 'h', 't', '\u000d\u000a',
                                     'o', 'l', 'l', 'e', 'h']

        assert list(graphemes('')) == []
