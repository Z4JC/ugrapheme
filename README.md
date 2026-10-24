## ugrapheme
*Unicode Extended grapheme clusters in nanoseconds*

[![PyPI - Version](https://img.shields.io/pypi/v/ugrapheme)](https://pypi.org/project/ugrapheme/)
[![PyPI - License](https://img.shields.io/pypi/l/ugrapheme)](https://github.com/Z4JC/ugrapheme/blob/main/LICENSE)
![PyPI - Downloads](https://img.shields.io/pypi/dm/ugrapheme)<br>
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Z4JC/ugrapheme/build_deploy.yml)](https://github.com/Z4JC/ugrapheme/actions/workflows/build_deploy.yml)
[![GitHub branch check runs](https://img.shields.io/github/check-runs/Z4JC/ugrapheme/main)](https://github.com/Z4JC/ugrapheme/actions/workflows/test.yml)
![PyPI - Status](https://img.shields.io/pypi/status/ugrapheme)
![PyPI - Wheel](https://img.shields.io/pypi/wheel/ugrapheme)<br>

Use `ugrapheme` to make your Python and Cython code see strings as a sequence of grapheme characters, so that the length of `👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi` is 4 instead of 13. 

Trivial operations like reversing a string, getting the first and last character, etc. become easy not just for Latin and Emojis, but Devanagari, Hangul, Tamil, Bengali, Arabic, etc. Centering and justifying Emojis and non-Latin text in terminal output becomes easy again, as `ugrapheme` uses [uwcwidth](https://github.com/Z4JC/uwcwidth) under the hood.

`ugrapheme` exposes an interface that's almost identical to Python's native strings and maintains a similar performance envelope, processing strings at hundreds of megabytes or even gigabytes per second:



|          graphemes        | graphemes<br>result | str             |  str<br>result  |
|--------------------------:|:--------------------|-----------------|-----------------|
| `g = graphemes('👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi')` |                     | `s = '👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi'`  |                 |
| `len(g)`                  | `4`                 | `len(s)`        | `13`            |
| `print(g[0])`             | `👩🏽‍🔬`                | `print(s[0])`   | `👩`            |
| `print(g[2])`             | `H`                 | `print(s[2])`   | `🔬`            |
| `print(g[2:])`            | `Hi`                | `print(s[2:])`  |` ‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi`        |
| `print(g[::-1])`          | `iH🏴󠁧󠁢󠁳󠁣󠁴󠁿👩🏽‍🔬`            | `print(s[::-1])`| `iH󠁿󠁴󠁣󠁳󠁢󠁧🏴🔬‍🏽👩`      |
| `g.find('🔬')`            | `-1`                | `s.find('🔬')`  | `3`             |
| `print(','.join(g))`      | `👩🏽‍🔬,🏴󠁧󠁢󠁳󠁣󠁴󠁿,H,i`         | `print(','.join(s))` | `👩,🏽,‍,🔬,🏴,󠁧,󠁢,󠁳,󠁣,󠁴,󠁿,H,i`
| `print(g.center(10, '-'))`| `--👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi--`        | `print(s.center(10, '-'))` | `👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi` |
| `print(max(g))`           | `👩🏽‍🔬`                | `print(max(s))` | unprintable     |
| `print(','.join(set(g)))` | `i,🏴󠁧󠁢󠁳󠁣󠁴󠁿,👩🏽‍🔬,H`         | `print(','.join(set(s)))` | `,H,󠁿,🏴,‍,󠁳,󠁴,i,󠁧,󠁢,🏽,👩,🔬` |

Just like native Python strings, `graphemes`  are hashable, iterable and pickleable.

Aside from passing the  [Unicode 16.0 UAX #29](https://www.unicode.org/reports/tr29/) Extended Grapheme Clusters grapheme break tests, `ugrapheme` correctly parses [many](https://users.rust-lang.org/t/how-to-work-with-strings-and-graphemes-similar-to-sql-how-to-avoid-crate-proliferation/55349/21?page=2) [difficult](https://stackoverflow.com/questions/78102711/get-python-characters-from-asian-text) [cases](https://stackoverflow.com/questions/78102711/get-python-characters-from-asian-text#comment137939643_78113676) [that break](https://gist.github.com/andjc/43a98c6d6f5e419303604081d57a401e) [other libraries](https://stackoverflow.com/questions/75210512/how-to-split-devanagari-bi-tri-and-tetra-conjunct-consonants-as-a-whole-from-a-s) in Python and [other languages](https://www.sololearn.com/en/discuss/2750995/how-to-reverse-unicoded-string-in-go-solved).

As of this writing (October 2024), `ugrapheme` is among the fastest and probably among more correct implementations across all programming languages and operating systems.

## Installation
```
pip install ugrapheme
```

## Basic usage

```python3
In [1]: from ugrapheme import graphemes
In [2]: g = graphemes("👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi")
In [3]: print(g[0])
👩🏽‍🔬
In [4]: print(g[-1])
i
In [5]: len(g)
Out[5]: 4
In [6]: print(g.center(10) + '\n0123456789')
  👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi
0123456789
In [7]: print(g * 5)
👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi
In [8]: print(g.join(["Ho", "Hey"]))
Ho👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿HiHey
In [9]: print(g.replace('🏴󠁧󠁢󠁳󠁣󠁴󠁿','<scotland>'))
👩🏽‍🔬<scotland>Hi
In [10]: namaste = graphemes('नमस्ते')
In [11]: list(namaste)
Out[11]: ['न', 'म', 'स्ते']
In [12]: print('>> ' + g[::-1] + namaste + ' <<')
>> iH🏴󠁧󠁢󠁳󠁣󠁴󠁿👩🏽‍🔬नमस्ते <<
```
## Documentation
Aside from this file, all public methods have detailed docstrings with examples, which should hopefully show up in IPython, VS Code, Jupyter Notebook or whatever else you happen to be using.

## Performance: [pyuegc](https://pypi.org/project/pyuegc/) 25x slower, [uniseg](https://pypi.org/project/uniseg/) 45x slower, ...
The popular Python grapheme splitting libraries are dramatically slower. Some could not even return the correct results despite spending orders of magnitude more CPU on the same task.

I gave these libraries the benefit of doubt by employing them on simple tasks such as returning the list of graphemes. The `graphemes` object takes an even smaller amount of time to build and takes less memory than a Python list of strings that these libraries expect you to work with, but let's try and do apples to apples here..

### [pyuegc](https://pypi.org/project/pyuegc/): 24x slower
```python3
In [1]: from pyuegc import EGC
In [2]: from ugrapheme import grapheme_split
In [3]: print(','.join(EGC("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")))
H,e,l,l,o, ,👩🏽‍🔬,!, ,👩🏼‍❤️‍💋‍👨🏾, ,अ,नु,च्छे,द
In [4]: print(','.join(grapheme_split("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")))
H,e,l,l,o, ,👩🏽‍🔬,!, ,👩🏼‍❤️‍💋‍👨🏾, ,अ,नु,च्छे,द
In [5]: %%timeit
   ...: EGC("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")
8.19 μs ± 77.5 ns per loop (mean ± std. dev. of 7 runs, 100,000 loops each)
In [6]: %%timeit
    ...: grapheme_split("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")
337 ns ± 3.4 ns per loop (mean ± std. dev. of 7 runs, 1,000,000 loops each)
```
### [uniseg](https://pypi.org/project/uniseg/): 45x slower, incorrect
```python3
In [1]: from uniseg.graphemecluster import grapheme_clusters
In [2]: from ugrapheme import grapheme_split
In [3]: print(','.join(grapheme_clusters("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")))  # Wrong
H,e,l,l,o, ,👩🏽‍🔬,!, ,👩🏼‍❤️‍💋‍👨🏾, ,अ,नु,च्,छे,द
In [4]: print(','.join(grapheme_split("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")))     # Correct
H,e,l,l,o, ,👩🏽‍🔬,!, ,👩🏼‍❤️‍💋‍👨🏾, ,अ,नु,च्छे,द
In [5]: %%timeit
    ...: list(grapheme_clusters("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद"))
14.6 μs ± 107 ns per loop (mean ± std. dev. of 7 runs, 100,000 loops each)
In [6]: %%timeit
    ...: grapheme_split("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")
340 ns ± 5.31 ns per loop (mean ± std. dev. of 7 runs, 1,000,000 loops each)
```
### [grapheme](https://pypi.org/project/grapheme/): 52x slower, incorrect

```python3
In [1]: from grapheme import graphemes
In [2]: from ugrapheme import grapheme_split
In [3]: print(','.join(graphemes("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")))         # Wrong
H,e,l,l,o, ,👩🏽‍🔬,!, ,👩🏼‍❤️‍💋‍👨🏾, ,अ,नु,च्,छे,द
In [4]: print(','.join(grapheme_split("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")))    # Correct
H,e,l,l,o, ,👩🏽‍🔬,!, ,👩🏼‍❤️‍💋‍👨🏾, ,अ,नु,च्छे,द
In [5]: %%timeit
   ...: list(graphemes("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद"))
17.4 μs ± 26.4 ns per loop (mean ± std. dev. of 7 runs, 100,000 loops each)
In [6]: %%timeit
   ...: grapheme_split("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")
332 ns ± 0.79 ns per loop (mean ± std. dev. of 7 runs, 1,000,000 loops each)
```

### [pyicu](https://pypi.org/project/PyICU/): 8x slower

```python3
In [1]: import icu
   ...: def iterate_breaks(text, break_iterator):
   ...:     text = icu.UnicodeString(text)
   ...:     break_iterator.setText(text)
   ...:     lastpos = 0
   ...:     while True:
   ...:         next_boundary = break_iterator.nextBoundary()
   ...:         if next_boundary == -1: return
   ...:         yield str(text[lastpos:next_boundary])
   ...:         lastpos = next_boundary
   ...: bi = icu.BreakIterator.createCharacterInstance(icu.Locale.getRoot())
In [2]: from ugrapheme import grapheme_split
In [3]: print(','.join(iterate_breaks("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद", bi)))
H,e,l,l,o, ,👩🏽‍🔬,!, ,👩🏼‍❤️‍💋‍👨🏾, ,अ,नु,च्छे,द
In [4]: print(','.join(grapheme_split("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")))
H,e,l,l,o, ,👩🏽‍🔬,!, ,👩🏼‍❤️‍💋‍👨🏾, ,अ,नु,च्छे,द
In [5]: %%timeit
   ...: list(iterate_breaks("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद", bi))
2.84 μs ± 23.5 ns per loop (mean ± std. dev. of 7 runs, 100,000 loops each)
In [6]: %%timeit
   ...: grapheme_split("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")
337 ns ± 4.1 ns per loop (mean ± std. dev. of 7 runs, 1,000,000 loops each)
```
In order for PyICU to split correctly, the strings need explicit conversion from/to `icu.UnicodeString`.  While Python strings index into Unicode codepoints/characters, the boundaries returned by PyICU iterators are unfortunately indices into a UTF-8 representation of the string, even if you pass in a native Python string initially. Thanks to Behdad Esfahbod of [harfbuzz](https://harfbuzz.github.io/) fame for catching this.

### [wcwidth](https://pypi.org/project/wcwidth/): 1.8x slower, correct
```python3
In [1]: from wcwidth import iter_graphemes
In [2]: from ugrapheme import grapheme_split
In [3]: print(','.join(iter_graphemes("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")))
H,e,l,l,o, ,👩🏽‍🔬,!, ,👩🏼‍❤️‍💋‍👨🏾, ,अ,नु,च्छे,द
In [4]: print(','.join(grapheme_split("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")))
H,e,l,l,o, ,👩🏽‍🔬,!, ,👩🏼‍❤️‍💋‍👨🏾, ,अ,नु,च्छे,द
In [5]: %%timeit
   ...: list(iter_graphemes("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद"))
677 ns ± 9.07 ns per loop (mean ± std. dev. of 7 runs, 1,000,000 loops each)
In [6]: %%timeit
   ...: grapheme_split("Hello 👩🏽‍🔬! 👩🏼‍❤️‍💋‍👨🏾 अनुच्छेद")
380 ns ± 10.7 ns per loop (mean ± std. dev. of 7 runs, 1,000,000 loops each)
```
note that python wcwidth uses an iterator, `iter_graphemes`, so `list()` is used.

python `wcwidth` uses the portable C11 [libwcwidth](https://wcwidth.readthedocs.io/en/latest/libwcwidth.html) library compiled into an abi3 module that covers all GIL-enabled python interpreters version 3.10 and newer, but this limited API reads text through `PyUnicode_ReadChar()` and `PyUnicode_Substring()`, while `ugrapheme` builds a Cython extension per-interpreter version and reads the PEP 393 buffer in place, with separate ASCII, Latin-1, UCS-2 and UCS-4 loops.

## Gotchas and performance tips
### Standalone functions for highest performance
The `graphemes` type is overall optimized for minimal CPU overhead, taking nanoseconds to instantiate and around 4 bytes extra for each string character. However, if you want absolutely the maximum performance and only want specific grapheme information, try the `grapheme_` family of standalone functions as these do not allocate memory or preprocess the input string in any way:

```python3
In [1]: from ugrapheme import (grapheme_len, grapheme_split,
    ...:  grapheme_iter, grapheme_at, grapheme_slice)
In [2]: grapheme_len("👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi")
Out[2]: 4

In [3]: grapheme_split('नमस्ते')
Out[3]: ['न', 'म', 'स्ते']

In [4]: grapheme_slice('👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi', 2, 4)
Out[4]: 'Hi'

In [5]: grapheme_at('नमस्ते', 2)
Out[5]: 'स्ते'

In [6]: for gr in grapheme_iter('👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi'):
    ...:     print(gr)
    ...:
👩🏽‍🔬
🏴󠁧󠁢󠁳󠁣󠁴󠁿
H
i
```
Just like the `graphemes` methods, the individual functions can be `cimported` into Cython for even less overhead.

### Concatenating
The fastest way to concatenate many `graphemes` and strings into another `graphemes` is to join them by using `graphemes('').join`, for example:

```python3
g2 = graphemes('').join(['>> ', g, ' -- ', namaste, ' <<'])
```
If you are just joining everything into a string, use the string `.join` method, it will work fine and be faster. Converting a `graphemes` object into a string is instantaneous, as `graphemes` works with native Python strings internally:

```python3
s2 = ''.join(['>> ', g, ' -- ', namaste, ' <<'])
```

### Slices are strings, not graphemes
When you take a slice of a `graphemes`, you get back a Python string.

If you want to keep working with `graphemes()`, use the `gslice` method: 

```python3
In [2]: g = graphemes("👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi")
In [3]: print(g[:2])
👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿
In [4]: len(g[:2])   # Returns 11, because g[:2] is a string
Out[4]: 11
In [5]: print(g.gslice(end=2))
👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿
In [6]: len(g.gslice(end=2))
Out[6]: 2
```
Using `gslice` constructs another `graphemes` object, which takes additional CPU and memory. Not returning `graphemes` saves a bunch of nanoseconds (percentage-wise) on very small strings, but unfortunately introduces this quirk.

### Cython
If you are using `graphemes` in a Cython project, you can further dramatically improve performance by doing a `cimport` of the provided `.pxd` files. There are fully-typed versions of operations such as accessing individual grapheme characters, slicing, find, replace, append, etc.


## Performance explained
### What's hard about this?
Not only are individual graphemes formed by rules that [take dozens of pages to describe](https://www.unicode.org/reports/tr29/), there's [tables](https://www.unicode.org/Public/16.0.0/ucd/auxiliary/GraphemeBreakProperty.txt) [that](https://www.unicode.org/Public/16.0.0/ucd/emoji/emoji-data.txt) [need](https://www.unicode.org/Public/16.0.0/ucd/DerivedCoreProperties.txt) to be consulted. If naively implemented, you are computing hashes for each codepoint and doing random access across hundreds of kilobytes or even megabytes of RAM.

To make things even more complex, Python internally represents strings in [different data formats](https://peps.python.org/pep-0393/) depending on whether they contain ASCII, Latin1, 2-byte unicode or 4-byte unicode characters and whether they are "compact" or not. `ugrapheme` internally understands the different formats and has separate low-level implementations for different combinations of underlying formats.

### Custom sparse bitmaps instead of tables, tries or maps
Using custom sparse bitmap datastructures, `ugrapheme` stores properties for every possible unicode codepoint in less than 11KB of data, comfortably fitting into [L1 cache](https://www.cs.utexas.edu/~fussell/courses/cs429h/lectures/Lecture_18-429h.pdf) of most CPUs produced in the last 20 years. The property lookup costs 2 loads, a few shifts and maybe a compare or two. Furthermore, similar characters occur in similar places, so for most text only a few smaller contiguous portions of tables are actually used and read.

### Simpler LL(1) parser / DFA
Instead of implementing the [state machine suggested by UAX #29](https://unicode.org/Public/16.0.0/ucd/auxiliary/GraphemeBreakTest.html), `ugrapheme` implements the rules as an [LL(1) grammar](https://www.csd.uwo.ca/~mmorenom/CS447/Lectures/Syntax.html/node14.html) parsed by a DFA with a very small number of states. An attempt is made towards a minimum number of codepoint property lookups to decide on a state transition. An unsigned comparison is used as an early [Bloom filter](https://en.wikipedia.org/wiki/Bloom_filter) for properties. Eventually, the CPU's branch predictor gets trained on the text you are processing and skips character classes your text does not belong to. Easier strings to process, such as those containing mostly ASCII or Latin1 will take less than a nanosecond per character on a fast 2024 laptop, reaching around 1.5 GB/second.

### CPython optimizations
The underlying Python string representation is kept and not copied or transformed, reducing memory pressure. Concatenations, joins, replications and substring replaces are done speculatively, assuming easy cases and reverting to more memory allocation or recalculations of underlying grapheme boundaries as rarely as possible.

Mirroring the [Reykjavik Need for Speed sprint](https://wiki.python.org/moin/NeedForSpeed/Successes) from 2 decades ago, the efforts of [Andrew Dalke](http://www.dalkescientific.com/) and late [Frederik Lundh](https://lwn.net/Articles/878325/) have been replicated in spirit, so that we can match or even sometimes beat the native Python string library. Generally, there's hand-coded solutions to subcases in instantiation, replicating, concatenating, search and replace when they give a significant performance advantage.

### Cython optimizations
In performance-critical loops, we sometimes do away with using Python/Cython object types and instead deal directly with the `PyObject *`, to avoid Cython generating unnecessary reference count increments and decrements. Decrements in  particular include checks and threaten to jump into a maze of deallocation code, confusing both the compiler and the CPU.

## Correctness
Like many other libraries, `ugrapheme` passes the unicode.org [UAX #29 suggested](https://www.unicode.org/reports/tr29/#Testing) [GraphemeBreakTest.txt](https://www.unicode.org/Public/16.0.0/ucd/auxiliary/GraphemeBreakTest.txt) . 

Separately, there's a brute-force exhaustive test over all possible unicode codepoints for `ugrapheme` custom sparse bitmap data structures.

Separate tests cover many cases where concatenating or replacing a portion of a grapheme changes the underlying grapheme boundaries.

Here's some examples of corner cases:

```python3
from ugrapheme import graphemes

len(graphemes('hi') + chr(13))
# outputs 3

len(graphemes('hi') + chr(13) + chr(10))
# also outputs 3, because chr(13) + chr(10) is a single grapheme!

len(graphemes('hi') + chr(10) + 'there')
# outputs 8

len((graphemes('hi') + chr(10) + 'there').replace('i', 'i' + chr(13)))
# also outputs 8, because chr(13) + chr(10) is a single grapheme! 

g = graphemes('Hi👍')
len(g)
# outputs 3

g += '🏾'  # Adding a Fitzpatrick skin type modifier...
len(g)     # ..does not change the grapheme length
# outputs 3
g
# outputs graphemes('Hi👍🏾')
```

Additionally, there's explicit tests for complicated graphemes known to have caused issues with other libraries, such as [Devanagari conjuncts](https://en.wikipedia.org/wiki/Devanagari_conjuncts).

For slicing, joining and replacing substrings, there are extra unittests done to make sure we always create the correct underlying python string representation (ASCII, Latin1, 2-byte or 4-byte).

## Limitations
`graphemes()` string length is limited to 4,294,967,294 unicode codepoints.

The stand-alone functions `grapheme_split`, `grapheme_len`, `grapheme_at`, etc. are not affected by this limit and work on all sizes.
## Giving credit

The whole library is licensed under the most permissive license I could find, so there are absolutely no legal requirements for giving credit.

However, outside of legal requirements, I promise that those who misrepresent this work as theirs will be [dealt with in a professional demoscene way](https://en.wiktionary.org/wiki/fuckings).

## License for Unicode Data Files (not packaged by default)

The test files for `ugrapheme`, available under `ugrapheme_ucd/data`
are

Copyright © 1991-2024 Unicode, Inc.

and provided under the UNICODE LICENSE V3. See `ugrapheme_ucd/data/LICENSE`.

The `ugrapheme_ucd/data` is not shipped with the `ugrapheme` library build, but only included inside the testing component.

## License

&copy; 2024 !ZAJC!/GDS 

Licensed under the BSD Zero Clause License. See LICENSE in
the project root, or the [SPDX 0BSD page](https://spdx.org/licenses/0BSD.html) for full license
information.

The [SPDX](https://spdx.dev) license identifier for this project is `0BSD`.
