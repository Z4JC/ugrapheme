#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
cimport cython

from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from cpython.list cimport PyList_GET_ITEM
from cpython.long cimport PyLong_Check
from cpython.object cimport PyObject
from cpython.pyport cimport PY_SSIZE_T_MIN, PY_SSIZE_T_MAX
from cpython.slice cimport PySlice_Check, PySlice_Unpack, PySlice_AdjustIndices
from cpython.tuple cimport PyTuple_GET_ITEM, PyTuple_GET_SIZE
from cpython.unicode cimport (PyUnicode_Check, PyUnicode_KIND, PyUnicode_Count,
                              PyUnicode_DATA, PyUnicode_GET_LENGTH,
                              PyUnicode_1BYTE_KIND, PyUnicode_2BYTE_KIND,
                              PyUnicode_4BYTE_KIND, PyUnicode_FromKindAndData,
                              PyUnicode_RichCompare, PyUnicode_Tailmatch,
                              PyUnicode_Find, PyUnicode_Concat,
                              PyUnicode_READ)

from libc.stdint cimport uint8_t, uint16_t, uint32_t, UINT32_MAX
from libc.string cimport memcpy
from ugrapheme.kk_copy cimport kk_copy, kk_copy_off
from ugrapheme.latin1 cimport init_latin1, get_latin1_unicode
from ugrapheme.uprop cimport (PyUnicode_New_by_Uprop, _PyUnicode_New_by_Uprop,
                              kind_from_uprop,
                              uprop_from_unicode, _uprop_from_unicode,
                              Uprop_ASCII, Uprop_Latin1,
                              Uprop_2BYTE, Uprop_4BYTE)
from ugrapheme.offsets cimport (_grapheme_offsets,
                                _grapheme_offsets_1byte_recalc,
                                _grapheme_offsets_2byte_recalc,
                                _grapheme_offsets_4byte_recalc)
from ugrapheme.ugrapheme cimport (grapheme_calc_tran,
                                  grapheme_calc_tran_1byte,
                                  grapheme_calc_tran_2byte,
                                  grapheme_calc_tran_4byte,
                                  grapheme_len,
                                  grapheme_split_uint32)
from ugrapheme.unicode_pyobject cimport (_PyUnicode_Check, _PyUnicode_DATA,
                                         _PyUnicode_GET_LENGTH,
                                         _PyUnicode_KIND,
                                         PyUnicode_Resize)

from uwcwidth cimport wcswidth


assert PyUnicode_1BYTE_KIND == 1
assert PyUnicode_2BYTE_KIND == 2
assert PyUnicode_4BYTE_KIND == 4

init_latin1()


cdef public class graphemes [type graphemes_type, object graphemes_obj]:
    def __init__(self, ustr):
        """Create a graphemes object from the given object (usually a string).

        Using a graphemes object is often exactly the same as using a string.
        Many methods are exactly the same, but each method is aware of
        grapheme characters. Grapheme characters are composed of several
        neighboring unicode characters/codepoints in a string.

        Example::
            g = graphemes('👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi')      s = '👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi'
            len(g) -> 4                  len(s) -> 13
            print(g[0]) -> 👩🏽‍🔬            print(s[0]) -> 👩
            print(g[2]) -> H             print(s[2]) -> 🔬
            print(g[2:]) -> Hi           print(s[2:]) -> ‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi
            print(g[::-1]) -> iH🏴󠁧󠁢󠁳󠁣󠁴󠁿👩🏽‍🔬     print(s[::-1]) -> iH󠁿󠁴󠁣󠁳󠁢󠁧🏴🔬‍🏽👩
            g.find('🔬') -> -1           s.find('🔬') -> 3
            print(','.join(g))           print(','.join(s))
              -> 👩🏽‍🔬,🏴󠁧󠁢󠁳󠁣󠁴󠁿,H,i                 -> 👩,🏽,‍,🔬,🏴,󠁧,󠁢,󠁳,󠁣,󠁴,󠁿,H,i
            print(g.center(10, '-'))     print(s.center(10, '-'))
              -> --👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi--               -> 👩🏽‍🔬🏴󠁧󠁢󠁳󠁣󠁴󠁿Hi
            print(max(g)) -> 👩🏽‍🔬          print(max(s)) -> #unprintable
            print(','.join(set(g)))      print(','.join(set(s)))
              -> i,🏴󠁧󠁢󠁳󠁣󠁴󠁿,👩🏽‍🔬,H                 -> 󠁣,H,󠁿,🏴,‍,󠁳,󠁴,i,󠁧,󠁢,🏽,👩,🔬

        Notice that center() adds 2 dashes on each side: it calculates
        correctly that the scientist and the flag occupy 2 monospace characters
        inside a terminal, making for a terminal length of 6 characters and
        needing extra 2 characters on each side to center the graphemes.

        If the object is a string, it is processed into a new graphemes object.
        If the object is graphemes, an identical object is created.
        Other kinds of objects are converted to a string and then processed
        into graphemes."""
        if isinstance(ustr, str):
            _init_from_str(self, <str> ustr)
        elif isinstance(ustr, graphemes):
            _init_from_graphemes(self, <graphemes> ustr)
        else:
            _init_from_str(self, str(ustr))

    def __dealloc__(self):
        PyMem_Free(self.off)

    @staticmethod
    cdef graphemes from_str(unicode ustr):
        if len(ustr) == 0:
            return _EMPTY_GRAPHEME
        cdef graphemes g = graphemes.__new__(graphemes)
        _init_from_str(g, ustr)
        return g

    @staticmethod
    cdef graphemes empty():
        return _EMPTY_GRAPHEME

    def __hash__(self):
        cdef PyObject *ustr = <PyObject *> self.ustr
        return _PyObject_Hash(ustr) + 0x12345678

    def __repr__(self):
        return 'graphemes(%r)' % self.ustr

    def __str__(self):
        return self.ustr

    def __iter__(self):
        cdef int kind = PyUnicode_KIND(self.ustr)
        if kind == PyUnicode_1BYTE_KIND:
            return _make_graphemes_byte_iter_fwd(self)
        elif kind == PyUnicode_2BYTE_KIND:
            return _make_graphemes_2byte_iter_fwd(self)
        else:
            return _make_graphemes_4byte_iter_fwd(self)

    def __reversed__(self):
        cdef int kind = PyUnicode_KIND(self.ustr)
        if kind == PyUnicode_1BYTE_KIND:
            return _make_graphemes_byte_iter_rev(self)
        elif kind == PyUnicode_2BYTE_KIND:
            return _make_graphemes_2byte_iter_rev(self)
        else:
            return _make_graphemes_4byte_iter_rev(self)

    def __reduce__(self):
        return (self.__class__, (self.ustr,))

    cpdef graphemes_offsets_iter offsets_iter(self):
        """Returns an iterator over offsets into grapheme characters.

    A graphemes string consists of grapheme characters which correspond
    to one or more unicode codepoints in the underlying string.

    Example: list(graphemes('Hi\\u000d\\u000athere').offsets_iter())
                returns [0, 1, 2, 4, 5, 6, 7, 8, 9]

    The grapheme 'H' begins at index 0 in the string 'Hi\\u000d\\u000athere'
    The grapheme 'i' begins at index 1 in the string
    The grapheme CRLF begins at index 2 in the string
    The grapheme 't' begins at index 4 in the string
     ...and so on
    The last offset returned corresponds to the total number of unicode
    codepoints needed to represent the underlying python string."""
        return _make_graphemes_offsets_iter(self)

    cdef uint32_t length(self):
        return self.gl

    cpdef unicode at(self, Py_ssize_t pos):
        """Returns a string corresponding to grapheme at position pos.

        Equivalent to doing G[pos], but faster"""
        return _at(self, pos)

    cdef unicode at_unsafe(self, Py_ssize_t pos):
        return _at_unsafe(self, pos)

    cpdef uint32_t off_at(self, Py_ssize_t pos) except 0xffffffff:
        """Returns the offset of grapheme at pos in the the underlying string.

        A graphemes string consists of grapheme characters which correspond
        to one or more unicode codepoints in the underlying string.

        If pos is at 1 position past the last grapheme, returns the
        of the underlying string in unicode characters.

        Example: graphemes('Hi\\u000d\\u000athere').off_at(3) -> 4

        Notice that we have letter 'H' at position 0, letter 'i' at
        position 1, the grapheme CRLF at position 2
        and then letter 't' at position 3. Inside the underlying python
        string, the letter 't' is at index (offset) 4."""
        if pos > self.gl:
            raise IndexError("index %d out of bounds" % pos)
        if pos < 0:
            pos += self.gl
            if pos < 0:
                raise IndexError("index %d out of bounds" % (pos - self.gl))
        return self.off[pos]

    cpdef uint32_t off_to_pos(self, Py_ssize_t off) except 0xffffffff:
        """Converts a grapheme offset into its corresponding position.

        A graphemes string consists of grapheme characters which correspond
        to one or more unicode codepoints in the underlying string.

        Examples: graphemes('Hi\\u000d\\u000athere').off_to_pos(4) -> 3
                  graphemes('Hi\\u000d\\u000athere').off_to_pos(2) -> 2
                  graphemes('Hi\\u000d\\u000athere').off_to_pos(3) -> 2

        Notice that we have letter 'H' at position 0, letter 'i' at
        position 1, the grapheme CRLF at position 2
        and then letter 't' at position 3. Inside the underlying python
        string, the letter 't' is at index (offset) 4.
        Notice also that offsets 2 and 3 both correspond to position 2,
        as the grapheme CRLF occupies 2 neighboring codepoints in the
        underlying python string."""
        if off > self.sl:
            raise IndexError("index %d out of bounds" % off)
        elif off == self.sl:
            return self.gl
        if off < 0:
            off += self.sl
            if off < 0:
                raise IndexError("index %d out of bounds" % (off - self.sl))
        return _off_to_pos_unsafe(self, off)

    cpdef graphemes gslice(self, Py_ssize_t start=PY_SSIZE_T_MIN,
                           Py_ssize_t end=PY_SSIZE_T_MAX,
                           Py_ssize_t step=1):
        """Returns a slice of graphemes as another graphemes instance.
        Doing a regular slice, for example G[1:4] or G[::-1] returns
        a standard python string. Calling gslice produces the same
        slice of graphemes, but returns a graphemes instance instead.

        Examples:
            graphemes('hello').gslice(1,4) -> graphemes('ell')
            graphemes('Hi🇭🇷').gslice(step=-1) -> graphemes('🇭🇷iH')
        """
        return _gslice(self, start, end, step)

    cdef unicode slice(self, Py_ssize_t pos, Py_ssize_t end):
        return _slice(self, pos, end)

    cdef unicode slice_unsafe(self, uint32_t pos, uint32_t end):
        return _slice_unsafe(self, pos, end)

    cdef unicode slice_stepped(self, Py_ssize_t pos, Py_ssize_t end,
                               Py_ssize_t step):
        return _stepped_slice(self, pos, end, step)

    def __getitem__(self, key):
        cdef Py_ssize_t pos, end, step
        if PySlice_Check(key):
            PySlice_Unpack(key, &pos, &end, &step)
            if step != 1:
                return _stepped_slice(self, pos, end, step)
            return _slice(self, pos, end)
        return _at(self, key)

    def __richcmp__(self, other, int op):
        if isinstance(other, str):
            return PyUnicode_RichCompare(self.ustr, <str> other, op)
        elif isinstance(other, graphemes):
            return PyUnicode_RichCompare(self.ustr,
                                         (<graphemes> other).ustr, op)
        return NotImplemented

    def __len__(self):
        return self.gl

    def __contains__(self, x):
        return _lrfind_dispatch(self, x, 1, 0, self.gl, False) != -1

    def __add__(self, x):
        if isinstance(x, str):
            return _append_str(self, <str> x)
        elif isinstance(x, graphemes):
            return _append_graphemes(self, <graphemes> x)
        else:
            return NotImplemented

    def __mul__(self, x):
        if not PyLong_Check(x):
            raise TypeError('can only replicate graphemes using '
                            'ints (not "%s")' % type(x).__name__)
        if x < 0:
            raise ValueError('replicating does not work with '
                             'negative numbers')
        if x >= UINT32_MAX:
            raise ValueError('replication count too large (%d)' % x)
        return _replicate_graphemes(self, x)

    def __radd__(self, x):
        if isinstance(x, str):
            return _append_graphemes(graphemes.from_str(<str> x), self)
        elif isinstance(x, graphemes):
            return _append_graphemes(<graphemes> x, self)
        else:
            return NotImplemented

    def __iadd__(self, x):
        if isinstance(x, str):
            return _append_str(self, <str> x)
        elif isinstance(x, graphemes):
            return _append_graphemes(self, <graphemes> x)
        else:
            raise TypeError('can only concatenate str or graphemes'
                            '(not "%s") to graphemes)' % type(x).__name__)

    cpdef graphemes append_str(self, unicode x):
        return _append_str(self, x)

    cpdef graphemes append_graphemes(self, graphemes x):
        return _append_graphemes(self, x)

    cpdef bint has(self, object x, bint partial=False) except 127:
        """Calling "G.has(x)" is identical to "x in G" when partial=False.

    Examples:
        graphemes('hello').has('e') -> True
        graphemes('Hi\\u000d\\u000athere').has('\\u000d') -> False
        graphemes('Hi\\u000d\\u000athere').has('\\u000d', partial=True) -> True

    If x is a grapheme in G, True is returned. x can be graphemes or str.
    If partial=True, True is returned even if x matches just a portion
    of a single grapheme"""
        if isinstance(x, str):
            return _lrfind_unsafe(
                self, <str> x, UINT32_MAX, 1, 0, self.gl, partial) != -1
        elif isinstance(x, graphemes):
            return _lrfind_unsafe(
                self, (<graphemes> x).ustr, (<graphemes> x).gl,
                1, 0, self.gl, partial) != -1
        else:
            raise TypeError("must be graphemes or str, not %s"
                            % type(x).__name__)

    cdef bint has_str(self, unicode x, bint partial=False) noexcept:
        return _lrfind_unsafe(
            self, <str> x, UINT32_MAX, 1, 0, self.gl, partial) != -1

    cdef bint has_graphemes(self, graphemes x, bint partial=False) noexcept:
        return _lrfind_unsafe(
            self, (<graphemes> x).ustr, (<graphemes> x).gl,
            1, 0, self.gl, partial) != -1

    cpdef Py_ssize_t count(self, object sub,
                           Py_ssize_t start=0, Py_ssize_t end=PY_SSIZE_T_MAX,
                           bint partial=False) except -1:
        """G.count(sub, start=0, end=*, partial=False) -> int

        Return the number of non-overlapping occurences of substring sub in
        the graphemes string G[start:end]. sub can be graphemes or string.
        Optional arguments start and end are interpreted as in slice notation.

        By default, sub is only counted if each grapheme in sub fully matches
        a grapheme in G. With partial=True, will also count occurences that
        only match a part of a grapheme."""
        return _count(self, sub, start, end, partial)

    cdef Py_ssize_t count_str(self, unicode sub,
                              Py_ssize_t start=0,
                              Py_ssize_t end=PY_SSIZE_T_MAX,
                              bint partial=False) noexcept:
        PySlice_AdjustIndices(self.gl, &start, &end, 1)
        return _count_unsafe(self, sub, UINT32_MAX, start, end, partial)

    cdef Py_ssize_t count_graphemes(self, graphemes sub,
                                    Py_ssize_t start=0,
                                    Py_ssize_t end=PY_SSIZE_T_MAX,
                                    bint partial=False) noexcept:
        PySlice_AdjustIndices(self.gl, &start, &end, 1)
        return _count_unsafe(self, (<graphemes> sub).ustr,
                             (<graphemes> sub).gl, start, end, partial)

    cpdef bint endswith(self, object suffix,
                        Py_ssize_t start=0, Py_ssize_t end=PY_SSIZE_T_MAX,
                        bint partial=False) except 127:
        """G.endswith(suffix, start=0, end=*, partial=False) -> bool

    Return True if G ends with the specified suffix, False otherwise.
    With optional start, test G beginning at that position.
    With optional end, stop comparing G at that position.
    suffix can be graphemes, a string or a tuple of strs or graphemes to try.

    By default, if a suffix starts in the middle of a grapheme, it is not a
    match. With partial=True, will return True even if the suffix begins inside
    of a grapheme."""
        return _startsendswith_dispatch(self, suffix, 1, start, end, partial)

    cpdef bint startswith(self, object prefix,
                          Py_ssize_t start=0, Py_ssize_t end=PY_SSIZE_T_MAX,
                          bint partial=False) except 127:
        """G.startswith(prefix, start=0, end=*, partial=False) -> bool

    Return True if G starts with the specified prefix, False otherwise.
    With optional start, test G beginning at that position.
    With optional end, stop comparing G at that position.
    prefix can be graphemes, a string or a tuple of strs or graphemes to try.

    By default, if a prefix ends in the middle of a grapheme, it is not a
    match. With partial=True, will return True even if the prefix ends inside
    of a grapheme."""
        return _startsendswith_dispatch(self, prefix, -1, start, end, partial)

    cpdef Py_ssize_t find(self, object sub,
                          Py_ssize_t start=0,
                          Py_ssize_t end=PY_SSIZE_T_MAX,
                          bint partial=False) except -2:
        """G.find(sub, start=0, end=*, partial=False) -> int

     Return the lowest index in G where substring sub is found,
     such that sub is contained within G[start:end].  Optional
     arguments start and end are interpreted as in slice notation.
     sub can be graphemes or string.

     By default, sub that only matches a part of a grapheme inside G
     is not a real match. If partial=True, matching only a part of a single
     grapheme is allowed.

     Return -1 if no matches found."""
        return _lrfind_dispatch(self, sub, 1, start, end, partial)

    cdef Py_ssize_t find_str(self, unicode sub,
                             Py_ssize_t start=0,
                             Py_ssize_t end=PY_SSIZE_T_MAX,
                             bint partial=False) noexcept:
        return _lrfind_str(self, sub, 1, start, end, partial)

    cdef Py_ssize_t find_graphemes(self, graphemes sub,
                                   Py_ssize_t start=0,
                                   Py_ssize_t end=PY_SSIZE_T_MAX,
                                   bint partial=False) noexcept:
        return _lrfind_graphemes(self, sub, 1, start, end, partial)

    cpdef Py_ssize_t rfind(self, object sub,
                           Py_ssize_t start=0,
                           Py_ssize_t end=PY_SSIZE_T_MAX,
                           bint partial=False) except -2:
        """G.rfind(sub, start=0, end=*, partial=False) -> int

     Return the highest index in G where substring sub is found,
     such that sub is contained within G[start:end].  Optional
     arguments start and end are interpreted as in slice notation.
     sub can be graphemes or string.

     By default, sub that only matches a part of a grapheme inside G
     is not a real match. If partial=True, matching only a part of a single
     grapheme is allowed.

     Return -1 if no matches found."""
        return _lrfind_dispatch(self, sub, -1, start, end, partial)

    cdef Py_ssize_t rfind_str(self, unicode sub,
                              Py_ssize_t start=0,
                              Py_ssize_t end=PY_SSIZE_T_MAX,
                              bint partial=False) noexcept:
        return _lrfind_str(self, sub, -1, start, end, partial)

    cdef Py_ssize_t rfind_graphemes(self, graphemes sub,
                                    Py_ssize_t start=0,
                                    Py_ssize_t end=PY_SSIZE_T_MAX,
                                    bint partial=False) noexcept:
        return _lrfind_graphemes(self, sub, -1, start, end, partial)

    cpdef Py_ssize_t index(self, object sub,
                           Py_ssize_t start=0,
                           Py_ssize_t end=PY_SSIZE_T_MAX,
                           bint partial=False) except -2:
        """G.index(sub, start=0, end=*, partial=False) -> int

     Return the lowest index in G where substring sub is found,
     such that sub is contained within G[start:end].  Optional
     arguments start and end are interpreted as in slice notation.
     sub can be graphemes or string.

     By default, sub that only matches a part of a grapheme inside G
     is not a real match. If partial=True, matching only a part of a single
     grapheme is allowed.

     Raises ValueError if no matches found."""
        cdef Py_ssize_t ret = _lrfind_dispatch(self, sub, 1, start, end,
                                               partial)
        if ret == -1:
            raise ValueError('substring not found')
        return ret

    cdef Py_ssize_t index_str(self, unicode sub,
                              Py_ssize_t start=0,
                              Py_ssize_t end=PY_SSIZE_T_MAX,
                              bint partial=False) except -2:
        cdef Py_ssize_t ret = _lrfind_str(self, sub, 1, start, end, partial)
        if ret == -1:
            raise ValueError('substring not found')
        return ret

    cdef Py_ssize_t index_graphemes(self, graphemes sub,
                                    Py_ssize_t start=0,
                                    Py_ssize_t end=PY_SSIZE_T_MAX,
                                    bint partial=False) except -2:
        cdef Py_ssize_t ret = _lrfind_graphemes(self, sub, 1,
                                                start, end, partial)
        if ret == -1:
            raise ValueError('substring not found')
        return ret

    cpdef Py_ssize_t rindex(self, object sub,
                            Py_ssize_t start=0,
                            Py_ssize_t end=PY_SSIZE_T_MAX,
                            bint partial=False) except -2:
        """G.rindex(sub, start=0, end=*, partial=False) -> int

     Return the highest index in G where substring sub is found,
     such that sub is contained within G[start:end].  Optional
     arguments start and end are interpreted as in slice notation.
     sub can be graphemes or string.

     By default, sub that only matches a part of a grapheme inside G
     is not a real match. If partial=True, matching only a part of a single
     grapheme is allowed.

     Raises ValueError if no matches found."""
        cdef Py_ssize_t ret = _lrfind_dispatch(self, sub, -1, start, end,
                                               partial)
        if ret == -1:
            raise ValueError('substring not found')
        return ret

    cdef Py_ssize_t rindex_str(self, unicode sub,
                               Py_ssize_t start=0,
                               Py_ssize_t end=PY_SSIZE_T_MAX,
                               bint partial=False) except -2:
        cdef Py_ssize_t ret = _lrfind_str(self, sub, -1, start, end, partial)
        if ret == -1:
            raise ValueError('substring not found')
        return ret

    cpdef graphemes replace(self, object old, object new, Py_ssize_t count=-1):
        """Return a copy with all occurrences of old replaced by new.
    old can be graphemes or str
    new can be graphemes or str

      count
        Maximum number of occurrences to replace.
        -1 (the default value) means replace all occurrences.

    If the optional argument count is given, only the first count occurrences
    are replaced."""
        return _replace(self, old, new, count)

    cdef Py_ssize_t rindex_graphemes(self, graphemes sub,
                                     Py_ssize_t start=0,
                                     Py_ssize_t end=PY_SSIZE_T_MAX,
                                     bint partial=False) except -2:
        cdef Py_ssize_t ret = _lrfind_graphemes(self, sub, -1,
                                                start, end, partial)
        if ret == -1:
            raise ValueError('substring not found')
        return ret

    cpdef unicode ljust(self, Py_ssize_t width, unicode fillchar=' ',
                        bint wcwidth=True):
        """Return a left-justified string of length width.

    Padding is done using the specified fill character (default is a space).
    By default, ljust considers the printable width inside a terminal.
    With wcwidth=False, ljust only uses the total number of unicode codepoints
    to calculate the padding size, just like in standard python strings."""

        return _lrjust(self, width, -1, fillchar, wcwidth)

    cpdef unicode rjust(self, Py_ssize_t width, unicode fillchar=' ',
                        bint wcwidth=True):
        """Return a right-justified string of length width.

    Padding is done using the specified fill character (default is a space).
    By default, rjust considers the printable width inside a terminal.
    With wcwidth=False, rjust only uses the total number of unicode codepoints
    to calculate the padding size, just like in standard python strings."""
        return _lrjust(self, width, 1, fillchar, wcwidth)

    cpdef unicode center(self, Py_ssize_t width, unicode fillchar=' ',
                         bint wcwidth=True):
        """Return a centered string of length width.

    Padding is done using the specified fill character (default is a space).
    By default, center considers the printable width inside a terminal.
    With wcwidth=False, center only uses the total number of unicode
    codepoints to calculate the padding size, just like in standard python
    strings."""
        return _lrjust(self, width, 0, fillchar, wcwidth)

    cpdef graphemes join(self, seq):
        """Concatenate any number of strings or graphemes

    The graphemes whose method is called is inserted in between each given
    element. A graphemes instance is returned.

    Example: graphemes('.').join(['ab', graphemes('pq'), 'rs'])
             returns graphemes('ab.pq.rs')
    """
        cdef list l = seq if isinstance(seq, list) else list(seq)
        cdef Py_ssize_t ll = len(l)
        cdef object first
        if ll == 0:
            return _EMPTY_GRAPHEME
        elif ll == 1:
            first = l[0]
            if isinstance(first, graphemes):
                return <graphemes> first
            else:
                return graphemes.from_str(first)

        if self.sl == 0:
            return _seq_concat(ll, l)
        return _seq_concat_sep(ll, l, <PyObject *> self)


@cython.cdivision(True)
cdef inline graphemes _seq_concat(Py_ssize_t ll, list l):
    cdef Py_ssize_t n_strs = 0, n_graphemes = 0
    cdef Py_ssize_t strs_len = 0, graphemes_cp_len = 0
    cdef int max_uprop = 0, cur_str_uprop = 0
    cdef PyObject *ustr = NULL
    cdef Py_ssize_t i
    cdef PyObject *pel
    for i in range(ll):
        pel = PyList_GET_ITEM(l, i)
        if _PyUnicode_Check(pel):
            strs_len += _PyUnicode_GET_LENGTH(pel)
            cur_str_uprop = _uprop_from_unicode(pel)
            if cur_str_uprop > max_uprop:
                max_uprop = cur_str_uprop
            n_strs += 1
        elif graphemes_Check(pel):
            graphemes_cp_len += graphemes_GET_SL(pel)
            ustr = _graphemes_GET_USTR(pel)
            cur_str_uprop = _uprop_from_unicode(ustr)
            if cur_str_uprop > max_uprop:
                max_uprop = cur_str_uprop
            n_graphemes += 1
        else:
            raise TypeError('can only concatenate str or graphemes, '
                            'not "%s"' % type(<object> pel).__name__)
    if n_graphemes == 0:
        return _seq_concat_strings(strs_len, max_uprop, l, ll)
    if (kind_from_uprop(max_uprop) == 1
         or graphemes_cp_len / n_graphemes < 3):
        return _seq_concat_stringify(strs_len + graphemes_cp_len,
                                     max_uprop, l, ll)
    if n_strs != 0:
        return _seq_concat_graphemes_or_strs(strs_len + graphemes_cp_len,
                                             max_uprop, l, ll)
    return _seq_concat_graphemes(graphemes_cp_len, max_uprop, l, ll)


@cython.cdivision(True)
cdef inline graphemes _seq_concat_sep(Py_ssize_t ll, list l, PyObject *sep_g):
    cdef Py_ssize_t n_strs = 0, n_graphemes = 0
    cdef Py_ssize_t strs_len = 0, graphemes_cp_len = 0
    cdef Py_ssize_t sep_len = ((ll - 1) * graphemes_GET_SL(sep_g)
                               if ll > 1 else 0)
    cdef int max_uprop = _uprop_from_unicode(_graphemes_GET_USTR(sep_g))
    cdef int cur_str_uprop = 0
    cdef PyObject *ustr = NULL
    cdef Py_ssize_t i
    cdef PyObject *pel
    for i in range(ll):
        pel = PyList_GET_ITEM(l, i)
        if _PyUnicode_Check(pel):
            strs_len += _PyUnicode_GET_LENGTH(pel)
            cur_str_uprop = _uprop_from_unicode(pel)
            if cur_str_uprop > max_uprop:
                max_uprop = cur_str_uprop
            n_strs += 1
        elif graphemes_Check(pel):
            graphemes_cp_len += graphemes_GET_SL(pel)
            ustr = _graphemes_GET_USTR(pel)
            cur_str_uprop = _uprop_from_unicode(ustr)
            if cur_str_uprop > max_uprop:
                max_uprop = cur_str_uprop
            n_graphemes += 1
        else:
            raise TypeError('can only concatenate str or graphemes, '
                            'not "%s"' % type(<object> pel).__name__)

    cdef uint32_t tot_len = strs_len + graphemes_cp_len + sep_len

    if n_graphemes == 0:
        return _seq_concat_sep_strings(tot_len, max_uprop, l, ll, sep_g)
    if (kind_from_uprop(max_uprop) == 1
         or graphemes_cp_len / n_graphemes < 3):
        return _seq_concat_sep_stringify(tot_len, max_uprop, l, ll, sep_g)
    if n_strs != 0:
        return _seq_concat_sep_graphemes_or_strs(tot_len, max_uprop, l, ll,
                                                 sep_g)
    return _seq_concat_sep_graphemes(tot_len, max_uprop, l, ll, sep_g)


cdef inline graphemes _seq_concat_strings(Py_ssize_t tsl, int max_uprop,
                                          list l, Py_ssize_t ll):
    cdef unicode out_ustr = PyUnicode_New_by_Uprop(tsl, max_uprop)
    cdef void *ch_out_ustr = PyUnicode_DATA(out_ustr)
    cdef uint8_t *ch_out_ustr8 = <uint8_t *> ch_out_ustr
    cdef Py_ssize_t i = 0
    cdef PyObject *pel

    if kind_from_uprop(max_uprop) == 1:
        for i in range(ll):
            pel = PyList_GET_ITEM(l, i)
            ch_out_ustr8 = _copyout_1byte_ustr(ch_out_ustr8, pel)
        return graphemes.from_str(out_ustr)

    for i in range(ll):
        pel = PyList_GET_ITEM(l, i)
        ch_out_ustr = _kk_copy_ustr(ch_out_ustr, kind_from_uprop(max_uprop),
                                    pel)
    return graphemes.from_str(out_ustr)


cdef inline graphemes _seq_concat_stringify(Py_ssize_t tsl, int max_uprop,
                                            list l, Py_ssize_t ll):
    cdef unicode out_ustr = PyUnicode_New_by_Uprop(tsl, max_uprop)
    cdef void *ch_out_ustr = PyUnicode_DATA(out_ustr)
    cdef int max_kind = kind_from_uprop(max_uprop)
    _copyout_strings_and_graphemes(ch_out_ustr, max_kind, l, ll)
    return graphemes.from_str(out_ustr)


cdef inline void _copyout_strings_and_graphemes(
     void *ch_out_ustr, int max_kind, list l, Py_ssize_t ll) noexcept:
    cdef uint8_t *ch_out_ustr8 = <uint8_t *> ch_out_ustr
    cdef Py_ssize_t i = 0
    cdef PyObject *pel = NULL

    if max_kind == 1:
        for i in range(ll):
            pel = PyList_GET_ITEM(l, i)
            ch_out_ustr8 = _copyout_1byte_ustr_or_graphemes(ch_out_ustr8, pel)
        return

    for i in range(ll):
        pel = PyList_GET_ITEM(l, i)
        ch_out_ustr = _kk_copy_ustr_or_graphemes(ch_out_ustr, max_kind, pel)


cdef inline graphemes _seq_concat_graphemes(Py_ssize_t tsl, int max_uprop,
                                            list l, Py_ssize_t ll):
    if tsl >= UINT32_MAX:
        raise ValueError("The resulting graphemes string is too long")

    cdef unicode out_ustr = PyUnicode_New_by_Uprop(tsl, max_uprop)
    _seq_concat_graphemes_ustr(PyUnicode_DATA(out_ustr), tsl,
                               kind_from_uprop(max_uprop), l, ll)

    cdef size_t new_off_size = (tsl + 1) * sizeof(uint32_t)
    cdef uint32_t *off = <uint32_t *> PyMem_Malloc(new_off_size)
    cdef uint32_t gl = _seq_concat_grapheme_offsets(
        off, PyUnicode_DATA(out_ustr), tsl, kind_from_uprop(max_uprop), l, ll)

    cdef graphemes g = graphemes.__new__(graphemes)
    g.ustr = out_ustr
    g.off = off
    g.gl = gl
    g.sl = tsl
    return g


cdef inline void _seq_concat_graphemes_ustr(void *ch_out_ustr,
                                            Py_ssize_t tsl, int max_kind,
                                            list l, Py_ssize_t ll) noexcept:
    cdef uint8_t *ch_out_ustr8 = <uint8_t *> ch_out_ustr
    cdef Py_ssize_t i = 0
    cdef PyObject *pel

    if max_kind == 1:
        for i in range(ll):
            pel = PyList_GET_ITEM(l, i)
            ch_out_ustr8 = _copyout_1byte_graphemes(ch_out_ustr8, pel)
        return

    for i in range(ll):
        pel = PyList_GET_ITEM(l, i)
        ch_out_ustr = _kk_copy_graphemes(ch_out_ustr, max_kind, pel)


ctypedef fused uintXX_t:
    uint8_t
    uint16_t
    uint32_t


cdef inline uint32_t _seq_concat_grapheme_offsets(
     uint32_t *off, void *ch_out_ustr, Py_ssize_t tsl, int max_kind,
     list l, Py_ssize_t ll) noexcept:
    if max_kind == 1:
        return _seq_concat_grapheme_offsets_uxx(off, <uint8_t *> ch_out_ustr,
                                                tsl, l, ll)
    elif max_kind == 2:
        return _seq_concat_grapheme_offsets_uxx(off, <uint16_t *> ch_out_ustr,
                                                tsl, l, ll)
    return _seq_concat_grapheme_offsets_uxx(off, <uint32_t *> ch_out_ustr,
                                            tsl, l, ll)


cdef inline uint32_t _seq_concat_grapheme_offsets_uxx(
     uint32_t *off, uintXX_t *ch_ustr, Py_ssize_t tsl,
     list l, Py_ssize_t ll) noexcept:
    cdef Py_ssize_t i = 0
    cdef PyObject *pel
    cdef uint32_t gl = 0, loff = 0

    for i in range(ll):
        pel = PyList_GET_ITEM(l, i)
        gl += _concat_grapheme_offsets(off, ch_ustr, pel, gl, &loff)

    off[gl] = loff

    return gl


cdef inline graphemes _seq_concat_graphemes_or_strs(
    Py_ssize_t tsl, int max_uprop, list l, Py_ssize_t ll):
    if tsl >= UINT32_MAX:
        raise ValueError("The resulting graphemes string is too long")

    cdef unicode out_ustr = PyUnicode_New_by_Uprop(tsl, max_uprop)
    cdef int max_kind = kind_from_uprop(max_uprop)
    _copyout_strings_and_graphemes(PyUnicode_DATA(out_ustr), max_kind, l, ll)

    cdef size_t new_off_size = (tsl + 1) * sizeof(uint32_t)
    cdef uint32_t *off = <uint32_t *> PyMem_Malloc(new_off_size)
    cdef uint32_t gl = _seq_concat_grapheme_or_str_offsets(
        off, PyUnicode_DATA(out_ustr), tsl, max_kind, l, ll)

    cdef graphemes g = graphemes.__new__(graphemes)
    g.ustr = out_ustr
    g.off = off
    g.gl = gl
    g.sl = tsl
    return g


cdef inline uint32_t _seq_concat_grapheme_or_str_offsets(
     uint32_t *off, void *ch_out_ustr, Py_ssize_t tsl, int max_kind,
     list l, Py_ssize_t ll) noexcept:
    if max_kind == 1:
        return _seq_concat_grapheme_or_str_offsets_uxx(
            off, <uint8_t *> ch_out_ustr, tsl, l, ll)
    elif max_kind == 2:
        return _seq_concat_grapheme_or_str_offsets_uxx(
            off, <uint16_t *> ch_out_ustr, tsl, l, ll)
    return _seq_concat_grapheme_or_str_offsets_uxx(
        off, <uint32_t *> ch_out_ustr, tsl, l, ll)


cdef inline uint32_t _seq_concat_grapheme_or_str_offsets_uxx(
     uint32_t *off, uintXX_t *ch_ustr, Py_ssize_t tsl,
     list l, Py_ssize_t ll) noexcept:
    cdef Py_ssize_t i = 0
    cdef PyObject *pel
    cdef uint32_t gl = 0, loff = 0

    for i in range(ll):
        pel = PyList_GET_ITEM(l, i)
        gl += _concat_grapheme_or_str_offsets(off, ch_ustr, pel, gl, &loff)

    off[gl] = loff

    return gl


cdef inline bint _will_break(uintXX_t *ch_ustr,
                             uint32_t cur_off, uint32_t nxt_off) noexcept:
    if uintXX_t is uint8_t:
        return not (ch_ustr[cur_off] == 13 and ch_ustr[nxt_off] == 10)
    elif uintXX_t is uint16_t:
        return grapheme_calc_tran_2byte(0, &ch_ustr[cur_off],
                                        nxt_off - cur_off + 1) & 0x100
    elif uintXX_t is uint32_t:
        return grapheme_calc_tran_4byte(0, &ch_ustr[cur_off],
                                        nxt_off - cur_off + 1) & 0x100

cdef inline uint32_t _concat_grapheme_offsets(
     uint32_t *off, uintXX_t *ch_ustr,
     PyObject *pg, uint32_t gl, uint32_t *ploff) noexcept:
    cdef uint32_t isl = graphemes_GET_SL(pg)
    cdef uint32_t loff = ploff[0]
    if isl == 0:
        return 0
    ploff[0] = loff + isl
    if loff == 0 or _will_break(ch_ustr, off[gl - 1], loff):
        return _offappend(off, pg, gl, loff)
    return _recalc_appended_offsets(ch_ustr, off, gl, isl, loff)


cdef inline uint32_t _concat_calc_str_offsets(
     uint32_t *off, uintXX_t *ch_ustr,
     PyObject *ustr, uint32_t gl, uint32_t *ploff) noexcept:
    cdef uint32_t isl = _PyUnicode_GET_LENGTH(ustr)
    cdef uint32_t loff = ploff[0]
    if isl == 0:
        return 0
    ploff[0] = loff + isl
    if loff == 0:
        return _calc_first_offsets(ch_ustr, off, isl)
    return _recalc_appended_offsets(ch_ustr, off, gl, isl, loff)


cdef inline uint32_t _concat_grapheme_or_str_offsets(
     uint32_t *off, uintXX_t *ch_ustr,
     PyObject *ustr_or_g, uint32_t gl, uint32_t *ploff) noexcept:
    if _PyUnicode_Check(ustr_or_g):
        return _concat_calc_str_offsets(off, ch_ustr, ustr_or_g, gl, ploff)
    return _concat_grapheme_offsets(off, ch_ustr, ustr_or_g, gl, ploff)


cdef inline uint32_t _calc_first_offsets(uintXX_t *ch_ustr, uint32_t *off,
                                         uint32_t isl) noexcept:
    off[0] = 0
    return _recalc_offsets(ch_ustr, off, 0, isl, 0) + 1


cdef inline uint32_t _recalc_appended_offsets(
     uintXX_t *ch_ustr, uint32_t *off, uint32_t gl, uint32_t isl,
     uint32_t loff) noexcept:
    return _recalc_offsets(ch_ustr, &off[gl - 1], off[gl - 1], loff + isl,
                           off[gl - 1])


cdef inline uint32_t _recalc_offsets(uintXX_t *ch_ustr, uint32_t *off,
                                     uint32_t pos_last, uint32_t pos_end,
                                     uint32_t loff) noexcept:
    cdef uint8_t *ch8_ustr = <uint8_t *> ch_ustr
    cdef uint16_t *ch16_ustr = <uint16_t *> ch_ustr
    cdef uint32_t *ch32_ustr = <uint32_t *> ch_ustr

    if uintXX_t is uint8_t:
        return _grapheme_offsets_1byte_recalc(ch8_ustr + pos_last,
                                              pos_end - pos_last,
                                              off, loff, 0) - 1
    elif uintXX_t is uint16_t:
        return _grapheme_offsets_2byte_recalc(ch16_ustr + pos_last,
                                              pos_end - pos_last,
                                              off, loff, 0) - 1
    elif uint32_t is uint32_t:
        return _grapheme_offsets_4byte_recalc(ch32_ustr + pos_last,
                                              pos_end - pos_last,
                                              off, loff, 0) - 1


cdef inline graphemes _seq_concat_sep_graphemes_or_strs(
    Py_ssize_t tsl, int max_uprop, list l, Py_ssize_t ll, PyObject *sep_g):
    if tsl >= UINT32_MAX:
        raise ValueError("The resulting graphemes string is too long")

    cdef unicode out_ustr = PyUnicode_New_by_Uprop(tsl, max_uprop)
    cdef int max_kind = kind_from_uprop(max_uprop)
    _copyout_strings_and_graphemes_sep(PyUnicode_DATA(out_ustr), max_kind,
                                       l, ll, sep_g)

    cdef size_t new_off_size = (tsl + 1) * sizeof(uint32_t)
    cdef uint32_t *off = <uint32_t *> PyMem_Malloc(new_off_size)
    cdef uint32_t gl = _seq_concat_sep_grapheme_or_str_offsets(
        off, PyUnicode_DATA(out_ustr), tsl, max_kind, l, ll, sep_g)
    cdef graphemes g = graphemes.__new__(graphemes)
    g.ustr = out_ustr
    g.off = off
    g.gl = gl
    g.sl = tsl
    return g


cdef inline graphemes _seq_concat_sep_graphemes(
     Py_ssize_t tsl, int max_uprop, list l, Py_ssize_t ll, PyObject *sep_g):
    if tsl >= UINT32_MAX:
        raise ValueError("The resulting graphemes string is too long")

    cdef unicode out_ustr = PyUnicode_New_by_Uprop(tsl, max_uprop)
    cdef int max_kind = kind_from_uprop(max_uprop)
    _seq_concat_sep_graphemes_ustr(PyUnicode_DATA(out_ustr), tsl,
                                   max_kind, l, ll, sep_g)

    cdef size_t new_off_size = (tsl + 1) * sizeof(uint32_t)
    cdef uint32_t *off = <uint32_t *> PyMem_Malloc(new_off_size)
    cdef uint32_t gl = _seq_concat_sep_grapheme_offsets(
        off, PyUnicode_DATA(out_ustr), tsl, max_kind, l, ll, sep_g)

    cdef graphemes g = graphemes.__new__(graphemes)
    g.ustr = out_ustr
    g.off = off
    g.gl = gl
    g.sl = tsl
    return g


cdef inline void _seq_concat_sep_graphemes_ustr(
     void *ch_out_ustr, Py_ssize_t tsl, int max_kind,
     list l, Py_ssize_t ll, PyObject *sep_g) noexcept:
    cdef uint8_t *ch_out_ustr8 = <uint8_t *> ch_out_ustr
    cdef Py_ssize_t i = 0
    cdef PyObject *pel = NULL
    cdef PyObject *sep_ustr = _graphemes_GET_USTR(sep_g)
    cdef void *ch_sep = _PyUnicode_DATA(sep_ustr)
    cdef int kind_sep = _PyUnicode_KIND(sep_ustr)
    cdef Py_ssize_t lsep = _PyUnicode_GET_LENGTH(sep_ustr)

    if max_kind == 1:
        pel = PyList_GET_ITEM(l, 0)
        ch_out_ustr8 = _copyout_1byte_graphemes(ch_out_ustr8, pel)
        for i in range(1, ll):
            memcpy(ch_out_ustr8, ch_sep, lsep)
            ch_out_ustr8 += lsep
            pel = PyList_GET_ITEM(l, i)
            ch_out_ustr8 = _copyout_1byte_graphemes(ch_out_ustr8, pel)
        return

    pel = PyList_GET_ITEM(l, 0)
    ch_out_ustr = _kk_copy_graphemes(ch_out_ustr, max_kind, pel)
    for i in range(1, ll):
        ch_out_ustr = kk_copy(ch_out_ustr, max_kind, ch_sep, kind_sep, lsep)
        pel = PyList_GET_ITEM(l, i)
        ch_out_ustr = _kk_copy_graphemes(ch_out_ustr, max_kind, pel)


cdef inline graphemes _seq_concat_sep_strings(
     Py_ssize_t tsl, int max_uprop, list l, Py_ssize_t ll, PyObject *sep_g):
    cdef unicode out_ustr = PyUnicode_New_by_Uprop(tsl, max_uprop)
    cdef int max_kind = kind_from_uprop(max_uprop)
    cdef void *ch_out_ustr = PyUnicode_DATA(out_ustr)
    cdef uint8_t *ch_out_ustr8 = <uint8_t *> ch_out_ustr
    cdef Py_ssize_t i = 0
    cdef PyObject *pel
    cdef PyObject *sep_ustr = _graphemes_GET_USTR(sep_g)
    cdef void *ch_sep = _PyUnicode_DATA(sep_ustr)
    cdef int kind_sep = _PyUnicode_KIND(sep_ustr)
    cdef Py_ssize_t lsep = _PyUnicode_GET_LENGTH(sep_ustr)

    if max_kind == 1:
        pel = PyList_GET_ITEM(l, 0)
        ch_out_ustr8 = _copyout_1byte_ustr(ch_out_ustr8, pel)
        for i in range(1, ll):
            memcpy(ch_out_ustr8, ch_sep, lsep)
            ch_out_ustr8 += lsep
            pel = PyList_GET_ITEM(l, i)
            ch_out_ustr8 = _copyout_1byte_ustr(ch_out_ustr8, pel)
        return graphemes.from_str(out_ustr)

    pel = PyList_GET_ITEM(l, 0)
    ch_out_ustr = _kk_copy_ustr(ch_out_ustr, max_kind, pel)
    for i in range(1, ll):
        ch_out_ustr = kk_copy(ch_out_ustr, max_kind, ch_sep, kind_sep, lsep)
        pel = PyList_GET_ITEM(l, i)
        ch_out_ustr = _kk_copy_ustr(ch_out_ustr, max_kind, pel)
    return graphemes.from_str(out_ustr)

cdef inline graphemes _seq_concat_sep_stringify(
     Py_ssize_t tsl, int max_uprop, list l, Py_ssize_t ll, PyObject *sep_g):
    cdef unicode out_ustr = PyUnicode_New_by_Uprop(tsl, max_uprop)
    cdef int max_kind = kind_from_uprop(max_uprop)
    cdef void *ch_out_ustr = PyUnicode_DATA(out_ustr)
    _copyout_strings_and_graphemes_sep(ch_out_ustr, max_kind, l, ll, sep_g)
    return graphemes.from_str(out_ustr)


cdef inline void _copyout_strings_and_graphemes_sep(
     void *ch_out_ustr, int max_kind, list l, Py_ssize_t ll,
     PyObject *sep_g) noexcept:
    cdef uint8_t *ch_out_ustr8 = <uint8_t *> ch_out_ustr
    cdef Py_ssize_t i = 0
    cdef PyObject *pel = NULL
    cdef PyObject *sep_ustr = _graphemes_GET_USTR(sep_g)
    cdef void *ch_sep = _PyUnicode_DATA(sep_ustr)
    cdef int kind_sep = _PyUnicode_KIND(sep_ustr)
    cdef Py_ssize_t lsep = _PyUnicode_GET_LENGTH(sep_ustr)

    if max_kind == 1:
        pel = PyList_GET_ITEM(l, 0)
        ch_out_ustr8 = _copyout_1byte_ustr_or_graphemes(ch_out_ustr8, pel)
        for i in range(1, ll):
            memcpy(ch_out_ustr8, ch_sep, lsep)
            ch_out_ustr8 += lsep
            pel = PyList_GET_ITEM(l, i)
            ch_out_ustr8 = _copyout_1byte_ustr_or_graphemes(ch_out_ustr8, pel)
        return

    pel = PyList_GET_ITEM(l, 0)
    ch_out_ustr = _kk_copy_ustr_or_graphemes(ch_out_ustr, max_kind, pel)
    for i in range(1, ll):
        ch_out_ustr = kk_copy(ch_out_ustr, max_kind, ch_sep, kind_sep, lsep)
        pel = PyList_GET_ITEM(l, i)
        ch_out_ustr = _kk_copy_ustr_or_graphemes(ch_out_ustr, max_kind, pel)


cdef inline uint32_t _seq_concat_sep_grapheme_offsets(
     uint32_t *off, void *ch_out_ustr, Py_ssize_t tsl, int max_kind,
     list l, Py_ssize_t ll, PyObject *sep_g) noexcept:
    if max_kind == 1:
        return _seq_concat_sep_grapheme_offsets_uxx(
            off, <uint8_t *> ch_out_ustr, tsl, l, ll, sep_g)
    elif max_kind == 2:
        return _seq_concat_sep_grapheme_offsets_uxx(
            off, <uint16_t *> ch_out_ustr, tsl, l, ll, sep_g)
    return _seq_concat_sep_grapheme_offsets_uxx(
        off, <uint32_t *> ch_out_ustr, tsl, l, ll, sep_g)


cdef inline uint32_t _seq_concat_sep_grapheme_offsets_uxx(
     uint32_t *off, uintXX_t *ch_ustr, Py_ssize_t tsl,
     list l, Py_ssize_t ll, PyObject *sep_g) noexcept:
    cdef Py_ssize_t i = 0
    cdef PyObject *pel
    cdef uint32_t gl = 0, loff = 0

    pel = PyList_GET_ITEM(l, 0)
    gl += _concat_grapheme_offsets(off, ch_ustr, pel, gl, &loff)

    for i in range(1, ll):
        gl += _concat_grapheme_offsets(off, ch_ustr, sep_g, gl, &loff)
        pel = PyList_GET_ITEM(l, i)
        gl += _concat_grapheme_offsets(off, ch_ustr, pel, gl, &loff)

    off[gl] = loff

    return gl


cdef inline uint32_t _seq_concat_sep_grapheme_or_str_offsets(
     uint32_t *off, void *ch_out_ustr, Py_ssize_t tsl, int max_kind,
     list l, Py_ssize_t ll, PyObject *sep_g) noexcept:
    if max_kind == 1:
        return _seq_concat_sep_grapheme_or_str_offsets_uxx(
            off, <uint8_t *> ch_out_ustr, tsl, l, ll, sep_g)
    elif max_kind == 2:
        return _seq_concat_sep_grapheme_or_str_offsets_uxx(
            off, <uint16_t *> ch_out_ustr, tsl, l, ll, sep_g)
    return _seq_concat_sep_grapheme_or_str_offsets_uxx(
        off, <uint32_t *> ch_out_ustr, tsl, l, ll, sep_g)


cdef inline uint32_t _seq_concat_sep_grapheme_or_str_offsets_uxx(
     uint32_t *off, uintXX_t *ch_ustr, Py_ssize_t tsl,
     list l, Py_ssize_t ll, PyObject *sep_g) noexcept:
    cdef Py_ssize_t i = 0
    cdef PyObject *pel
    cdef uint32_t gl = 0, loff = 0

    pel = PyList_GET_ITEM(l, 0)
    gl += _concat_grapheme_or_str_offsets(off, ch_ustr, pel, gl, &loff)

    for i in range(1, ll):
        gl += _concat_grapheme_offsets(off, ch_ustr, sep_g, gl, &loff)
        pel = PyList_GET_ITEM(l, i)
        gl += _concat_grapheme_or_str_offsets(off, ch_ustr, pel, gl, &loff)

    off[gl] = loff

    return gl


cdef inline graphemes _append_str(graphemes self, unicode x):
    cdef Py_ssize_t xsl = PyUnicode_GET_LENGTH(x)
    if xsl == 0:
        return self
    if xsl + <Py_ssize_t> self.sl >= UINT32_MAX:
        raise ValueError("This string is too large")

    cdef size_t new_off_size = (self.gl + xsl + 1) * sizeof(uint32_t)
    cdef uint32_t *off = <uint32_t *> PyMem_Malloc(new_off_size)

    cdef unicode ustr = PyUnicode_Concat(self.ustr, x)
    memcpy(off, self.off, (self.gl + 1) * sizeof(uint32_t))

    cdef uint32_t init_len, last_grapheme_off, n_reparsed
    cdef uint32_t *p_last_grapheme_off

    if self.gl > 0:
        init_len = self.gl - 1
        p_last_grapheme_off = &off[init_len]
        last_grapheme_off = off[init_len]
        n_reparsed = off[init_len + 1] - off[init_len]
    else:
        n_reparsed = 0
        init_len = 0
        p_last_grapheme_off = off
        last_grapheme_off = 0

    cdef uint32_t xgl = _grapheme_offsets(
        ustr=ustr, l=xsl + n_reparsed, out=p_last_grapheme_off,
        initial=last_grapheme_off, upos=last_grapheme_off) - 1

    cdef graphemes g = graphemes.__new__(graphemes)
    g.ustr = ustr
    g.off = off
    g.gl = init_len + xgl
    g.sl = self.sl + xsl
    return g


cdef inline graphemes _append_graphemes(graphemes self, graphemes xg):
    cdef Py_ssize_t xsl = xg.sl
    if xsl == 0:
        return self
    if self.sl == 0:
        return xg
    if xsl + <Py_ssize_t> self.sl >= UINT32_MAX:
        raise ValueError("This string is too large")

    cdef size_t new_off_size = (self.gl + xsl + 1) * sizeof(uint32_t)
    cdef uint32_t *off = <uint32_t *> PyMem_Malloc(new_off_size)

    cdef unicode ustr = PyUnicode_Concat(self.ustr, xg.ustr)
    memcpy(off, self.off, (self.gl + 1) * sizeof(uint32_t))

    cdef uint32_t init_len = self.gl - 1
    cdef uint32_t *p_last_grapheme_off = &off[init_len]
    cdef uint32_t last_grapheme_off = off[init_len], lboundary = off[self.gl]
    cdef uint32_t n_reparsed = lboundary - last_grapheme_off

    if xsl > 1:
        _grapheme_offsets(ustr=ustr, l=1 + n_reparsed, out=p_last_grapheme_off,
                          initial=last_grapheme_off, upos=last_grapheme_off)

    cdef uint32_t gl = 0, xgl = 0
    if xsl > 1 and off[self.gl] == lboundary:
        _offcopy(&off[self.gl], &xg.off[0], xg.gl + 1, lboundary)
        gl = self.gl + xg.gl
    else:
        xgl = _grapheme_offsets(
            ustr=ustr, l=xsl + n_reparsed, out=p_last_grapheme_off,
            initial=last_grapheme_off, upos=last_grapheme_off) - 1
        gl = init_len + xgl

    cdef graphemes g = graphemes.__new__(graphemes)
    g.ustr = ustr
    g.off = off
    g.sl = self.sl + xsl
    g.gl = gl
    return g


cdef inline uint32_t _offappend(uint32_t *off, PyObject *pg, uint32_t gl,
                                uint32_t loff) noexcept:
    cdef uint32_t igl = graphemes_GET_GL(pg)
    _offcopy(&off[gl], graphemes_GET_OFF(pg), igl, loff)
    return igl


cdef inline void _offcopy(uint32_t *dest, uint32_t *src, uint32_t l,
                          uint32_t off) noexcept:
    cdef uint32_t i
    for i in range(l):
        dest[i] = src[i] + off


cdef inline _init_from_str(graphemes self, unicode ustr):
    self.ustr = ustr
    cdef Py_ssize_t sl = PyUnicode_GET_LENGTH(ustr)
    if sl >= UINT32_MAX:
        raise ValueError("This string is too big")
    self.sl = sl
    self.off = <uint32_t *> PyMem_Malloc(sizeof(uint32_t) * (self.sl + 1))
    if sl > 0:
        self.gl = _grapheme_offsets(ustr, self.sl, self.off, 0, 0) - 1
    else:
        self.off[0] = 0
        self.gl = 0


cdef inline _init_from_graphemes(graphemes self, graphemes g_in):
    self.ustr = g_in.ustr
    self.sl = g_in.sl
    self.gl = g_in.gl
    cdef size_t off_sz = sizeof(uint32_t) * (self.gl + 1)
    self.off = <uint32_t *> PyMem_Malloc(off_sz)
    memcpy(self.off, g_in.off, off_sz)


cdef inline graphemes _make_empty_graphemes():
    cdef graphemes g = graphemes.__new__(graphemes)
    g.ustr = ''
    g.sl = 0
    g.off = <uint32_t *> PyMem_Malloc(sizeof(uint32_t))
    g.off[0] = 0
    g.gl = 0
    return g


cdef graphemes _EMPTY_GRAPHEME = _make_empty_graphemes()
cdef unicode _CR_LF = '\u000d\u000a'


cdef inline bint _startsendswith_dispatch(
     graphemes self, object suffix, int direction,
     Py_ssize_t start, Py_ssize_t end, bint partial):
    if isinstance(suffix, str):
        return _startsendswith(
            self, (<str> suffix), -1,
            direction, start, end, partial)
    elif isinstance(suffix, graphemes):
        return _startsendswith(
            self, (<graphemes> suffix).ustr, (<graphemes> suffix).gl,
            direction, start, end, partial)
    elif isinstance(suffix, tuple):
        return _startsendswith_tuple(self, (<tuple> suffix), direction,
                                     start, end, partial)
    raise TypeError('%s first arg must be either str, graphemes'
                    ' or a tuple of str or graphemes, not %s'
                    % (('endswith' if direction == 1 else 'startswith'),
                       type(suffix).__name__))


cdef inline bint _startsendswith_tuple(
     graphemes self, tuple suffixes, int direction,
     Py_ssize_t start, Py_ssize_t end, bint partial) except 127:
    cdef Py_ssize_t i, lt = PyTuple_GET_SIZE(suffixes)
    cdef PyObject *el

    for i in range(lt):
        el = PyTuple_GET_ITEM(suffixes, i)
        if _PyUnicode_Check(el):
            if _startsendswith(self, <unicode> el, -1,
                               direction, start, end, partial):
                return True
            continue
        if graphemes_Check(el):
            if _startsendswith(self, graphemes_GET_USTR(el),
                               graphemes_GET_GL(el), direction, start, end,
                               partial):
                return True
            continue
        raise TypeError('tuple for %s must only contain graphemes or str, '
                        'not %s' % (
                            ('endswith' if direction == 1 else 'startswith'),
                            type(<object> el).__name__))
    return False


cdef inline bint _startsendswith(graphemes self, unicode suffix,
                                 Py_ssize_t sgl, int direction,
                                 Py_ssize_t start, Py_ssize_t end,
                                 bint partial) noexcept:
    PySlice_AdjustIndices(self.gl, &start, &end, 1)
    cdef Py_ssize_t ustart = self.off[start], uend = self.off[end]
    if partial:
        return PyUnicode_Tailmatch(self.ustr, suffix, ustart, uend, direction)

    cdef Py_ssize_t suflen = PyUnicode_GET_LENGTH(suffix)
    if sgl >= 0:
        if direction < 0:
            if (start + sgl > self.gl
                 or self.off[start + sgl] != ustart + suflen):
                return False
        else:
            if (end - sgl < 0
                 or self.off[end - sgl] != uend - suflen):
                return False
        return PyUnicode_Tailmatch(self.ustr, suffix, ustart, uend, direction)

    if PyUnicode_Tailmatch(self.ustr, suffix, ustart, uend, direction):
        sgl = grapheme_len(suffix)
        if direction < 0:
            if (start + sgl > self.gl
                 or self.off[start + sgl] != ustart + suflen):
                return False
            return True
        if (end - sgl < 0
             or self.off[end - sgl] != uend - suflen):
            return False
        return True
    return False


cdef inline graphemes _replace(graphemes self, object old, object new,
                               Py_ssize_t count=-1):
    cdef unicode o_ustr
    cdef unicode n_ustr
    cdef uint32_t o_gl = UINT32_MAX
    cdef bint new_is_grapheme = False

    if isinstance(old, str):
        o_ustr = <str> old
    elif isinstance(old, graphemes):
        o_ustr = (<graphemes> old).ustr
        o_gl = (<graphemes> old).gl
    else:
        raise TypeError('replace argument 1 must be graphemes or str, '
                        'not %s' % type(old).__name__)
    if isinstance(new, str):
        n_ustr = <str> new
    elif isinstance(new, graphemes):
        n_ustr = (<graphemes> new).ustr
        new_is_grapheme = True
    else:
        raise TypeError('replace argument 2 must be graphemes or str, '
                        'not %s' % type(old).__name__)

    if count == 0:
        return self

    cdef PyObject *my_ustr = <PyObject *> self.ustr
    cdef int my_uprop = _uprop_from_unicode(my_ustr)
    cdef int old_uprop = uprop_from_unicode(o_ustr)

    if old_uprop > my_uprop:
        return self

    cdef uint32_t my_len = _PyUnicode_GET_LENGTH(my_ustr)
    cdef uint32_t o_len = PyUnicode_GET_LENGTH(o_ustr)
    if o_len > my_len:
        return self

    cdef PyObject *pnew = <PyObject *> new
    if o_len == 0:
        return _replace_blankold(self, my_uprop, pnew, new_is_grapheme, count)

    cdef Py_ssize_t first_off = -1

    cdef uint8_t *my_u8 = <uint8_t *> _PyUnicode_DATA(my_ustr)
    cdef uint8_t *o_u8 = <uint8_t *> PyUnicode_DATA(o_ustr)

    cdef int new_uprop = uprop_from_unicode(n_ustr)

    if kind_from_uprop(my_uprop) == PyUnicode_1BYTE_KIND:
        if kind_from_uprop(new_uprop) == PyUnicode_1BYTE_KIND:
            if _is_never_at_boundary_1byte(o_u8, o_len):
                return graphemes.from_str(self.ustr.replace(o_ustr, n_ustr,
                                                            count))
            first_off = _replace_find_off_1byte(my_u8, my_len, o_u8, o_len, 0)
            if first_off == -1:
                return self
            return _replace_1byte(self, o_ustr, n_ustr,
                                  my_uprop, new_uprop, first_off, count)

    cdef uint32_t old_ch = 0, new_ch = 0
    if o_len == 1 and PyUnicode_GET_LENGTH(n_ustr) == 1:
        old_ch = <uint32_t> PyUnicode_READ(kind_from_uprop(old_uprop),
                                           PyUnicode_DATA(o_ustr), 0)
        new_ch = <uint32_t> PyUnicode_READ(kind_from_uprop(new_uprop),
                                           PyUnicode_DATA(n_ustr), 0)
        return _replace_mbyte_1cp(self, my_uprop, new_uprop,
                                  old_ch, new_ch, count)

    if o_gl == UINT32_MAX:
        o_gl = grapheme_len(o_ustr)

    cdef PyObject *newo = <PyObject *> new
    if new_is_grapheme:
        return _replace_mbyte(self, o_ustr, o_gl,
                              _graphemes_GET_USTR(newo),
                              graphemes_GET_GL(newo),
                              graphemes_GET_OFF(newo), count)

    cdef uint32_t lnew = _PyUnicode_GET_LENGTH(newo)
    cdef uint32_t *newoff = <uint32_t *> PyMem_Malloc(sizeof(uint32_t)
                                                      * (lnew + 1))
    cdef uint32_t ngl = _grapheme_offsets(n_ustr, lnew, newoff, 0, 0) - 1
    try:
        return _replace_mbyte(self, o_ustr, o_gl, newo, ngl, newoff, count)
    finally:
        PyMem_Free(newoff)


cdef graphemes _replace_blankold(
     graphemes self, int my_uprop,
     PyObject *pnew, bint new_is_grapheme, Py_ssize_t count):
    cdef uint32_t lself = self.sl

    if lself == 0:
        if new_is_grapheme:
            return _as_graphemes_object(pnew)
        return graphemes.from_str(_as_str_object(pnew))

    cdef PyObject *n_ustr = (_graphemes_GET_USTR(pnew) if new_is_grapheme
                             else pnew)
    cdef uint32_t lnew = _PyUnicode_GET_LENGTH(n_ustr)
    if lnew == 0:
        return self

    cdef PyObject *selfu = <PyObject *> self.ustr
    cdef int self_uprop = _uprop_from_unicode(selfu)
    cdef void *vself = _PyUnicode_DATA(selfu)
    cdef uint32_t sgl = self.gl
    cdef uint32_t *selfoff = self.off
    cdef int new_uprop = _uprop_from_unicode(n_ustr)
    cdef void *vnew = _PyUnicode_DATA(n_ustr)
    cdef void *ebuf = NULL

    cdef int max_uprop = self_uprop
    cdef int self_kind = kind_from_uprop(self_uprop)
    cdef int max_kind = self_kind
    cdef int new_kind = kind_from_uprop(new_uprop)

    if new_uprop > self_uprop:
        max_uprop = new_uprop
        max_kind = new_kind
        if new_kind > self_kind:
            vself = ebuf = _kind_extend(max_kind, vself, self_kind, lself)
    else:
        if self_kind > new_kind:
            vnew = ebuf = _kind_extend(max_kind, vnew, new_kind, lnew)

    try:
        if max_kind == PyUnicode_1BYTE_KIND:
            return _replace_blankold_u8(
                <uint8_t *> vself, lself, sgl,
                <uint8_t *> vnew, lnew, max_uprop, count)
        elif max_kind == PyUnicode_2BYTE_KIND:
            return _replace_blankold_uxx(
                <uint16_t *> vself, lself, sgl, selfoff,
                <uint16_t *> vnew, lnew, max_uprop, count)
        return _replace_blankold_uxx(
            <uint32_t *> vself, lself, sgl, selfoff,
            <uint32_t *> vnew, lnew, max_uprop, count)
    finally:
        PyMem_Free(ebuf)


cdef inline graphemes _replace_blankold_u8(
    uint8_t *self8, uint32_t sl, uint32_t sgl, uint8_t *new8, uint32_t lnew,
    int max_uprop, Py_ssize_t count):
    if count < 0 or count > sgl + 1:
        count = sgl + 1

    cdef PyObject *pres = _PyUnicode_New_by_Uprop(sl + count * lnew,
                                                  max_uprop)
    cdef uint8_t *res_ustr8 = <uint8_t *> _PyUnicode_DATA(pres)

    memcpy(res_ustr8, new8, lnew)

    cdef uint32_t roff = 0, woff = lnew
    cdef Py_ssize_t cur_count = 1

    while cur_count < count:
        if self8[roff] == 13 and self8[roff + 1] == 10:
            res_ustr8[woff] = 13
            res_ustr8[woff + 1] = 10
            woff += 2
            roff += 2
        else:
            res_ustr8[woff] = self8[roff]
            woff += 1
            roff += 1
        memcpy(res_ustr8 + woff, new8, lnew)
        woff += lnew
        cur_count += 1
        if roff == sl:
            break

    if roff < sl:
        memcpy(res_ustr8 + woff, self8 + roff, sl - roff)

    return graphemes.from_str(_as_str_object(pres))


cdef inline graphemes _replace_blankold_uxx(
     uintXX_t *selfx, uint32_t sl, uint32_t sgl, uint32_t *selfoff,
     uintXX_t *newx, uint32_t lnew, int max_uprop, Py_ssize_t count):
    if count < 0 or count > sgl + 1:
        count = sgl + 1

    cdef PyObject *pres = _PyUnicode_New_by_Uprop(sl + count * lnew,
                                                  max_uprop)
    cdef uintXX_t *resx = <uintXX_t *> _PyUnicode_DATA(pres)
    cdef size_t ch_sz = sizeof(uintXX_t)

    memcpy(resx, newx, lnew * ch_sz)

    cdef uint32_t roff = 0, woff = lnew, ch_l = 0
    cdef Py_ssize_t cur_count = 1

    while cur_count < count:
        ch_l = selfoff[cur_count] - roff
        memcpy(resx + woff, selfx + roff, ch_l * ch_sz)
        woff += ch_l
        roff += ch_l
        memcpy(resx + woff, newx, lnew * ch_sz)
        woff += lnew
        cur_count += 1
        if roff >= sl:
            break

    if roff < sl:
        memcpy(resx + woff, selfx + roff, (sl - roff) * ch_sz)

    return graphemes.from_str(_as_str_object(pres))


cdef inline Py_ssize_t _replace_find_off_1byte(
     uint8_t *self8, uint32_t sl, uint8_t *old8, uint32_t lold,
     Py_ssize_t ustart) noexcept:
    cdef uint32_t pos = ustart
    while pos < sl - lold + 1:
        if self8[pos] == 10 and pos > 0 and self8[pos - 1] == 13:
            pos += 1
            if pos >= sl:
                return -1

        if not _check_match8(self8 + pos, old8, lold):
            pos += 1
            continue

        if (self8[pos + lold - 1] != 13 or pos + lold >= sl
             or self8[pos + lold] != 10):
            return pos

        pos += 1
    return -1


cdef inline bint _check_match8(uint8_t *s, uint8_t *sub, uint32_t l) noexcept:
    cdef uint32_t i
    for i in range(l):
        if s[i] != sub[i]:
            return False
    return True


cdef inline graphemes _replace_1byte(
    graphemes self, unicode o_ustr, unicode n_ustr,
    int self_uprop, int new_uprop, uint32_t first_off, Py_ssize_t count):
    cdef bint maybe_crunch = new_uprop < self_uprop
    cdef int max_uprop = self_uprop if maybe_crunch else new_uprop
    cdef uint32_t lold = PyUnicode_GET_LENGTH(o_ustr)
    cdef uint8_t *old8 = <uint8_t *> PyUnicode_DATA(o_ustr)
    cdef uint8_t *self8 = <uint8_t *> PyUnicode_DATA(self.ustr)

    cdef Py_ssize_t lnew_big = PyUnicode_GET_LENGTH(n_ustr)
    if lnew_big >= UINT32_MAX:
        raise ValueError("The new string is too long")

    cdef uint32_t lnew = lnew_big
    cdef uint8_t *new8 = <uint8_t *> PyUnicode_DATA(n_ustr)

    if lnew <= lold:
        return _replace_1byte_newsmaller(
            self8, self.sl, old8, lold, new8, lnew, max_uprop, maybe_crunch,
            first_off, count)
    return _replace_1byte_newbigger(
        self8, self.sl, old8, lold, new8, lnew, max_uprop, maybe_crunch,
        first_off, count)


cdef inline graphemes _replace_1byte_newsmaller(
     uint8_t *self8, uint32_t sl, uint8_t *old8, uint32_t lold,
     uint8_t *new8, uint32_t lnew, int max_uprop, bint maybe_crunch,
     uint32_t first_off, Py_ssize_t count):
    cdef PyObject *pres = _PyUnicode_New_by_Uprop(sl, max_uprop)
    cdef uint8_t *res_ustr8 = <uint8_t *> _PyUnicode_DATA(pres)
    cdef uint32_t roff = 0, woff = 0, cur_count = 0, rem = 0
    cdef Py_ssize_t off = first_off

    while True:
        memcpy(res_ustr8 + woff, self8 + roff, off - roff)
        woff += off - roff
        roff = off + lold
        memcpy(res_ustr8 + woff, new8, lnew)
        woff += lnew

        if count > 0:
            cur_count += 1

        off = _replace_find_off_1byte(self8, sl, old8, lold, roff)

        if off == -1 or (count > 0 and cur_count == count):
            rem = sl - roff
            memcpy(res_ustr8 + woff, self8 + roff, rem)
            roff += rem
            woff += rem
            break

    if lold != lnew:
        PyUnicode_Resize(&pres, woff)
        res_ustr8 = <uint8_t *> _PyUnicode_DATA(pres)

    if maybe_crunch:
        pres = maybe_down_size(pres, res_ustr8, woff)

    return graphemes.from_str(_as_str_object(pres))


cdef inline graphemes _replace_1byte_newbigger(
     uint8_t *self8, uint32_t sl, uint8_t *old8, uint32_t lold,
     uint8_t *new8, uint32_t lnew, int max_uprop, bint maybe_crunch,
     uint32_t first_off, Py_ssize_t count):
    cdef uint32_t lplus = lnew - lold
    cdef uint32_t reserve = 1
    cdef PyObject *pres = _PyUnicode_New_by_Uprop(sl + lplus * reserve,
                                                  max_uprop)
    cdef uint8_t *res_ustr8 = <uint8_t *> _PyUnicode_DATA(pres)
    cdef uint32_t roff = 0, woff = 0, cur_count = 0, rem = 0
    cdef Py_ssize_t off = first_off

    while True:
        memcpy(res_ustr8 + woff, self8 + roff, off - roff)
        woff += off - roff
        roff = off + lold
        memcpy(res_ustr8 + woff, new8, lnew)
        woff += lnew

        cur_count += 1

        off = _replace_find_off_1byte(self8, sl, old8, lold, roff)
        if off == -1 or (count > 0 and cur_count == count):
            rem = sl - roff
            memcpy(res_ustr8 + woff, self8 + roff, rem)
            roff += rem
            woff += rem
            break

        if cur_count >= reserve:
            reserve *= 2
            PyUnicode_Resize(&pres, sl + lplus * reserve)
            res_ustr8 = <uint8_t *> _PyUnicode_DATA(pres)

    if reserve != cur_count:
        PyUnicode_Resize(&pres, woff)
        res_ustr8 = <uint8_t *> _PyUnicode_DATA(pres)

    if maybe_crunch:
        pres = maybe_down_size(pres, res_ustr8, woff)

    return graphemes.from_str(_as_str_object(pres))


cdef bint _is_never_at_boundary_1byte(uint8_t *old8, uint32_t lold) noexcept:
    cdef uint8_t fch = old8[0]
    cdef uint8_t lch = old8[lold - 1]

    return (fch > 13 and lch > 13 or
            (fch != 13 and fch != 10 and lch != 13 and lch != 10))


cdef inline bint _check_match_uxx(uintXX_t *s, uintXX_t *sub,
                                  uint32_t l) noexcept:
    cdef uint32_t i
    for i in range(l):
        if s[i] != sub[i]:
            return False
    return True


cdef inline Py_ssize_t _replace_find_pos_uxx(
     uintXX_t *selfx, uint32_t lself, uint32_t sgl,
     uintXX_t *oldx, uint32_t lold, uint32_t ogl,
     uint32_t *selfoff, Py_ssize_t offstart) noexcept:

    cdef uint32_t pos = 0, opos = offstart
    while opos < lself - lold + 1:
        if _check_match_uxx(selfx + opos, oldx, lold):
            pos = _replace_off_to_pos(selfoff, sgl, opos)
            if opos + lold == selfoff[pos + ogl]:
                return pos

        opos += 1
    return -1


cdef inline uint32_t _replace_off_to_pos(uint32_t *off_a, uint32_t gl, uint32_t off) noexcept:
    cdef uint32_t pos_lo = 0, pos_mid = 0, pos_hi = gl
    cdef uint32_t off_mid = 0, off_mid_hi = 0
    pos_mid = off
    if pos_mid >= gl:
        pos_mid = gl - 1
    while pos_lo < pos_hi:
        off_mid = off_a[pos_mid]
        off_mid_hi = off_a[pos_mid + 1]
        if off >= off_mid_hi:
            pos_lo = pos_mid + 1
        else:
            if off >= off_mid:
                return pos_mid
            pos_hi = pos_mid
        pos_mid = (pos_lo + pos_hi) >> 1
    return pos_mid


cdef inline Py_ssize_t _replace_find_pos_uxx_1cp(
     uintXX_t *resx, uint32_t lself, uint32_t rgl,
     uint32_t old_ch, uint32_t *resoff, Py_ssize_t offstart) noexcept:

    cdef uint32_t pos = 0, opos = offstart
    while opos < lself:
        if resx[opos] == old_ch:
            pos = _replace_off_to_pos(resoff, rgl, opos)
            if opos + 1 == resoff[pos + 1]:
                return pos

        opos += 1
    return -1


cdef inline void _copy_off_uxx(uintXX_t *dst, uint32_t woff,
                               uintXX_t *src, uint32_t roff,
                               uint32_t l) noexcept:
    if uintXX_t is uint8_t:
        memcpy(&dst[woff], &src[roff], l)
    elif uintXX_t is uint16_t:
        memcpy(&dst[woff], &src[roff], l * 2)
    elif uintXX_t is uint32_t:
        memcpy(&dst[woff], &src[roff], l * 4)


cdef inline uint32_t max_ch_uxx(uintXX_t *resx, uint32_t sl) noexcept:
    cdef uint32_t i
    cdef uint32_t max_ch = 0

    for i in range(sl):
        if resx[i] > max_ch:
            max_ch = resx[i]
    return max_ch


cdef inline int check_down_uprop(uintXX_t *resx, uint32_t sl) noexcept:
    cdef uint32_t max_ch = max_ch_uxx(resx, sl)

    if uintXX_t is uint8_t:
        if max_ch > 0x7F:
            return 0
        else:
            return Uprop_ASCII
    elif uintXX_t is uint16_t:
        if max_ch > 0xFF:
            return 0
        elif max_ch > 0x7F:
            return Uprop_Latin1
        else:
            return Uprop_ASCII
    else:
        max_ch = max_ch_uxx(resx, sl)
        if max_ch > 0xFFFF:
            return 0
        elif max_ch > 0xFF:
            return Uprop_2BYTE
        elif max_ch > 0x7F:
            return Uprop_Latin1
        else:
            return Uprop_ASCII


cdef inline void down_copy_uxx(void *downx, int down_kind,
                               uintXX_t *resx, uint32_t sl) noexcept:
    cdef uint8_t *down8 = <uint8_t *> downx
    cdef uint16_t *down16 = <uint16_t *> downx
    cdef uint32_t i

    if uintXX_t is uint8_t:
        memcpy(down8, resx, sl)
        return
    elif uintXX_t is uint16_t:
        for i in range(sl):
            down8[i] = resx[i]
        return
    else:
        if down_kind == PyUnicode_1BYTE_KIND:
            for i in range(sl):
                down8[i] = resx[i]
            return

        for i in range(sl):
            down16[i] = resx[i]


cdef inline PyObject *maybe_down_size(PyObject *res,
                                      uintXX_t *resx, uint32_t sl):
    cdef int down_uprop = check_down_uprop(resx, sl)
    if down_uprop == 0:
        return res

    cdef PyObject *newres = _PyUnicode_New_by_Uprop(sl, down_uprop)
    down_copy_uxx(_PyUnicode_DATA(newres), kind_from_uprop(down_uprop),
                  resx, sl)

    _Py_DECREF(res)
    return newres


cdef inline graphemes _replace_mbyte_1cp(
     graphemes self, int my_uprop, int new_uprop,
     uint32_t old_ch, uint32_t new_ch, Py_ssize_t count):
    cdef PyObject *ustr = <PyObject *> self.ustr
    cdef void *vdata = _PyUnicode_DATA(ustr)
    cdef void *ebuf = NULL
    cdef int max_uprop = my_uprop
    cdef int my_kind = kind_from_uprop(my_uprop)
    cdef Py_ssize_t first_pos = 0

    if my_kind == PyUnicode_1BYTE_KIND:
        first_pos = _replace_find_pos_uxx_1cp(
            <uint8_t *> vdata, self.sl, self.gl, old_ch, self.off, 0)
    elif my_kind == PyUnicode_2BYTE_KIND:
        first_pos = _replace_find_pos_uxx_1cp(
            <uint16_t *> vdata, self.sl, self.gl, old_ch, self.off, 0)
    else:
        first_pos = _replace_find_pos_uxx_1cp(
            <uint32_t *> vdata, self.sl, self.gl, old_ch, self.off, 0)

    if first_pos == -1:
        return self

    cdef bint maybe_crunch = False

    cdef int new_kind = kind_from_uprop(new_uprop)
    if new_uprop > my_uprop:
        if new_kind > my_kind:
            vdata = ebuf = _kind_extend(new_kind, vdata, my_kind, self.sl)
        max_uprop = new_uprop
    elif new_uprop < my_uprop:
        maybe_crunch = True

    try:
        if kind_from_uprop(max_uprop) == PyUnicode_2BYTE_KIND:
            return _replace_mbyte_uxx_1cp(
                <uint16_t *> vdata, self.sl, self.gl, self.off,
                old_ch, new_ch, max_uprop, maybe_crunch, first_pos, count)
        return _replace_mbyte_uxx_1cp(
            <uint32_t *> vdata, self.sl, self.gl, self.off,
            old_ch, new_ch, max_uprop, maybe_crunch, first_pos, count)
    finally:
        PyMem_Free(ebuf)


cdef inline graphemes _replace_mbyte_uxx_1cp(
     uintXX_t *selfx, uint32_t sl, uint32_t sgl, uint32_t *selfoff,
     uint32_t old_ch, uint32_t new_ch,
     int max_uprop, bint maybe_crunch, uint32_t first_pos, Py_ssize_t count):
    cdef PyObject *pres = _PyUnicode_New_by_Uprop(sl, max_uprop)
    cdef uintXX_t *resx = <uintXX_t *> _PyUnicode_DATA(pres)
    _copy_off_uxx(resx, 0, selfx, 0, sl)

    cdef uint32_t selfoff_sz = sizeof(uint32_t) * (sgl + 1)
    cdef uint32_t *resoff = <uint32_t *> PyMem_Malloc(
        sizeof(uint32_t) * (sgl + 1))
    memcpy(resoff, selfoff, selfoff_sz)

    cdef uint32_t cur_count = 0
    cdef Py_ssize_t off = selfoff[first_pos], pos = first_pos
    cdef uint32_t rgl = 0, hpos = 0

    cdef bint hard = False

    while True:
        resx[off] = new_ch
        cur_count += 1
        if ((off > 0 and not _will_break(resx, off - 1, off))
            or (off + 1 < sgl and not _will_break(resx, off, off + 1))):
            hard = 1
            break

        if count > 0 and cur_count == count:
            break

        pos = _replace_find_pos_uxx_1cp(
            selfx, sl, sgl, old_ch, selfoff, off + 1)
        if pos == -1:
            break

        off = selfoff[pos]

    if hard:
        hpos = pos
        resoff = <uint32_t *> PyMem_Realloc(resoff,
                                            sizeof(uint32_t) * (sl + 1))
        while count < 0 or cur_count != count:
            pos = _replace_find_pos_uxx_1cp(
                selfx, sl, sgl, old_ch, selfoff, off + 1)
            if pos == -1:
                break
            off = selfoff[pos]
            resx[off] = new_ch
            cur_count += 1
        if hpos > 0:
            rgl = hpos + _recalc_appended_offsets(resx, resoff, hpos, sl, 0)
        else:
            rgl = _calc_first_offsets(resx, resoff, sl)
        resoff[rgl] = sl
    else:
        rgl = sgl

    if maybe_crunch:
        pres = maybe_down_size(pres, resx, sl)

    cdef graphemes g = graphemes.__new__(graphemes)
    g.ustr = _as_str_object(pres)
    g.off = resoff
    g.gl = rgl
    g.sl = sl
    return g


cdef inline graphemes _replace_mbyte(
     graphemes self, unicode old, uint32_t ogl,
     PyObject *newu, uint32_t ngl, uint32_t *newoff, Py_ssize_t count):
    cdef PyObject *selfu = <PyObject *> self.ustr
    cdef int self_uprop = _uprop_from_unicode(selfu)
    cdef void *vself = _PyUnicode_DATA(selfu)
    cdef uint32_t lself = self.sl
    cdef uint32_t sgl = self.gl
    cdef uint32_t *selfoff = self.off
    cdef int old_uprop = uprop_from_unicode(old)
    cdef uint32_t lold = PyUnicode_GET_LENGTH(old)
    cdef void *vold = PyUnicode_DATA(old)
    cdef int new_uprop = _uprop_from_unicode(newu)
    cdef uint32_t lnew = _PyUnicode_GET_LENGTH(newu)
    cdef void *vnew = _PyUnicode_DATA(newu)
    cdef void *ebuf1 = NULL
    cdef void *ebuf2 = NULL

    cdef int max_uprop = self_uprop
    cdef int self_kind = kind_from_uprop(self_uprop)
    cdef int max_kind = self_kind
    cdef int old_kind = kind_from_uprop(old_uprop)
    cdef int new_kind = kind_from_uprop(new_uprop)
    cdef bint maybe_crunch = False

    if new_uprop > self_uprop:
        max_uprop = new_uprop
        max_kind = new_kind
        if new_kind > self_kind:
            vself = ebuf1 = _kind_extend(max_kind, vself, self_kind, lself)
            vold = ebuf2 = _kind_extend(max_kind, vold, old_kind, lold)
    else:
        if self_uprop > new_uprop:
            maybe_crunch = True
            if self_kind > new_kind:
                vnew = ebuf1 = _kind_extend(max_kind, vnew, new_kind, lnew)
        if self_kind > old_kind:
            vold = ebuf2 = _kind_extend(max_kind, vold, old_kind, lold)

    cdef Py_ssize_t first_pos = 0

    try:
        if lnew <= lold:
            if lnew == 0:
                if max_kind == PyUnicode_2BYTE_KIND:
                    first_pos = _replace_find_pos_uxx(
                        <uint16_t *> vself, lself, sgl,
                        <uint16_t *> vold, lold, ogl, selfoff, 0)
                    if first_pos == -1:
                        return self
                    return _replace_mbyte_uxx_newzero(
                        <uint16_t *> vself, lself, sgl, selfoff,
                        <uint16_t *> vold, lold, ogl,
                        max_uprop, maybe_crunch, first_pos, count)
                first_pos = _replace_find_pos_uxx(
                    <uint32_t *> vself, lself, sgl,
                    <uint32_t *> vold, lold, ogl, selfoff, 0)
                if first_pos == -1:
                    return self
                return _replace_mbyte_uxx_newzero(
                    <uint32_t *> vself, lself, sgl, selfoff,
                    <uint32_t *> vold, lold, ogl,
                    max_uprop, maybe_crunch, first_pos, count)
            if max_kind == PyUnicode_2BYTE_KIND:
                first_pos = _replace_find_pos_uxx(
                    <uint16_t *> vself, lself, sgl,
                    <uint16_t *> vold, lold, ogl, selfoff, 0)
                if first_pos == -1:
                    return self
                return _replace_mbyte_uxx_newsmaller(
                    <uint16_t *> vself, lself, sgl, selfoff,
                    <uint16_t *> vold, lold, ogl,
                    <uint16_t *> vnew, lnew, ngl, newoff,
                    max_uprop, maybe_crunch, first_pos, count)
            first_pos = _replace_find_pos_uxx(
                <uint32_t *> vself, lself, sgl,
                <uint32_t *> vold, lold, ogl, selfoff, 0)
            if first_pos == -1:
                return self
            return _replace_mbyte_uxx_newsmaller(
                <uint32_t *> vself, lself, sgl, selfoff,
                <uint32_t *> vold, lold, ogl,
                <uint32_t *> vnew, lnew, ngl, newoff,
                max_uprop,  maybe_crunch, first_pos, count)
        if max_kind == PyUnicode_2BYTE_KIND:
            first_pos = _replace_find_pos_uxx(
                <uint16_t *> vself, lself, sgl,
                <uint16_t *> vold, lold, ogl, selfoff, 0)
            if first_pos == -1:
                return self
            return _replace_mbyte_uxx(
                <uint16_t *> vself, lself, sgl, selfoff,
                <uint16_t *> vold, lold, ogl,
                <uint16_t *> vnew, lnew, ngl, newoff,
                max_uprop, maybe_crunch, first_pos, count)
        first_pos = _replace_find_pos_uxx(
            <uint32_t *> vself, lself, sgl,
            <uint32_t *> vold, lold, ogl, selfoff, 0)
        if first_pos == -1:
            return self
        return _replace_mbyte_uxx(
            <uint32_t *> vself, lself, sgl, selfoff,
            <uint32_t *> vold, lold, ogl,
            <uint32_t *> vnew, lnew, ngl, newoff,
            max_uprop, maybe_crunch, first_pos, count)
    finally:
        PyMem_Free(ebuf1)
        PyMem_Free(ebuf2)


cdef inline void * _kind_extend(int new_kind, void *old_data, int old_kind,
                                uint32_t l):
    cdef void *new_data = PyMem_Malloc(new_kind * l)
    kk_copy(new_data, new_kind, old_data, old_kind, l)
    return new_data


cdef inline graphemes _replace_mbyte_uxx_newzero(
     uintXX_t *selfx, uint32_t sl, uint32_t sgl, uint32_t *selfoff,
     uintXX_t *oldx, uint32_t lold, uint32_t ogl,
     int max_uprop, bint maybe_crunch, uint32_t first_pos, Py_ssize_t count):
    cdef PyObject *pres = _PyUnicode_New_by_Uprop(sl, max_uprop)
    cdef uint32_t *resoff = <uint32_t *> PyMem_Malloc(
        sizeof(uint32_t) * (sl + 1))
    cdef uintXX_t *resx = <uintXX_t *> _PyUnicode_DATA(pres)
    cdef uint32_t roff = 0, woff = 0, cur_count = 0, rem = 0
    cdef Py_ssize_t off = selfoff[first_pos], pos = first_pos, rpos = 0
    cdef uint32_t rgl = 0, loff = 0

    while True:
        _copy_off_uxx(resx, woff, selfx, roff, off - roff)
        rgl += _replace_concat_grapheme_offsets(
            resx, resoff, rgl, selfoff, pos, rpos, off - roff, &loff)
        woff += off - roff
        roff = off + lold

        cur_count += 1

        rpos = pos + ogl
        pos = _replace_find_pos_uxx(
            selfx, sl, sgl, oldx, lold, ogl, selfoff, roff)
        if pos == -1 or (count > 0 and cur_count == count):
            break

        off = selfoff[pos]

    rem = sl - roff
    if rem > 0:
        _copy_off_uxx(resx, woff, selfx, roff, rem)
        rgl += _replace_concat_grapheme_offsets(
            resx, resoff, rgl, selfoff, sgl, rpos, rem, &loff)
        roff += rem
        woff += rem
    resoff[rgl] = woff

    PyUnicode_Resize(&pres, woff)
    resx = <uintXX_t *> _PyUnicode_DATA(pres)

    if maybe_crunch:
        pres = maybe_down_size(pres, resx, woff)

    cdef graphemes g = graphemes.__new__(graphemes)
    g.ustr = _as_str_object(pres)
    g.off = resoff
    g.gl = rgl
    g.sl = woff
    return g


cdef inline graphemes _replace_mbyte_uxx_newsmaller(
     uintXX_t *selfx, uint32_t sl, uint32_t sgl, uint32_t *selfoff,
     uintXX_t *oldx, uint32_t lold, uint32_t ogl,
     uintXX_t *newx, uint32_t lnew, uint32_t ngl, uint32_t *newoff,
     int max_uprop, bint maybe_crunch, uint32_t first_pos, Py_ssize_t count):
    cdef PyObject *pres = _PyUnicode_New_by_Uprop(sl, max_uprop)
    cdef uint32_t *resoff = <uint32_t *> PyMem_Malloc(
        sizeof(uint32_t) * (sl + 1))
    cdef uintXX_t *resx = <uintXX_t *> _PyUnicode_DATA(pres)
    cdef uint32_t roff = 0, woff = 0, cur_count = 0, rem = 0
    cdef Py_ssize_t off = selfoff[first_pos], pos = first_pos, rpos = 0
    cdef uint32_t nsl = newoff[ngl]
    cdef uint32_t rgl = 0, loff = 0

    while True:
        _copy_off_uxx(resx, woff, selfx, roff, off - roff)
        rgl += _replace_concat_grapheme_offsets(
            resx, resoff, rgl, selfoff, pos, rpos, off - roff, &loff)
        woff += off - roff
        roff = off + lold
        _copy_off_uxx(resx, woff, newx, 0, lnew)
        rgl += _replace_concat_grapheme_offsets(
            resx, resoff, rgl, newoff, ngl, 0, nsl, &loff)
        woff += lnew

        cur_count += 1

        rpos = pos + ogl
        pos = _replace_find_pos_uxx(
            selfx, sl, sgl, oldx, lold, ogl, selfoff, roff)
        if pos == -1 or (count > 0 and cur_count == count):
            break

        off = selfoff[pos]

    rem = sl - roff
    if rem > 0:
        _copy_off_uxx(resx, woff, selfx, roff, rem)
        rgl += _replace_concat_grapheme_offsets(
            resx, resoff, rgl, selfoff, sgl, rpos, rem, &loff)
        roff += rem
        woff += rem
    resoff[rgl] = woff

    if lold != lnew:
        PyUnicode_Resize(&pres, woff)
        resx = <uintXX_t *> _PyUnicode_DATA(pres)

    if maybe_crunch:
        pres = maybe_down_size(pres, resx, woff)

    cdef graphemes g = graphemes.__new__(graphemes)
    g.ustr = _as_str_object(pres)
    g.off = resoff
    g.gl = rgl
    g.sl = woff
    return g


cdef inline graphemes _replace_mbyte_uxx(
     uintXX_t *selfx, uint32_t sl, uint32_t sgl, uint32_t *selfoff,
     uintXX_t *oldx, uint32_t lold, uint32_t ogl,
     uintXX_t *newx, uint32_t lnew, uint32_t ngl, uint32_t *newoff,
     int max_uprop, bint maybe_crunch, uint32_t first_pos, Py_ssize_t count):
    cdef uint32_t lplus = lnew - lold if lnew > lold else 0
    cdef uint32_t reserve = 1
    cdef PyObject *pres = _PyUnicode_New_by_Uprop(sl + lplus * reserve,
                                                  max_uprop)
    cdef uint32_t *resoff = <uint32_t *> PyMem_Malloc(
        sizeof(uint32_t) * (sl + 1 + lplus * reserve))
    cdef uintXX_t *resx = <uintXX_t *> _PyUnicode_DATA(pres)
    cdef uint32_t roff = 0, woff = 0, cur_count = 0, rem = 0
    cdef Py_ssize_t off = selfoff[first_pos], pos = first_pos, rpos = 0
    cdef uint32_t nsl = newoff[ngl]
    cdef uint32_t rgl = 0, loff = 0

    while True:
        _copy_off_uxx(resx, woff, selfx, roff, off - roff)
        rgl += _replace_concat_grapheme_offsets(
            resx, resoff, rgl, selfoff, pos, rpos, off - roff, &loff)
        woff += off - roff
        roff = off + lold
        _copy_off_uxx(resx, woff, newx, 0, lnew)
        rgl += _replace_concat_grapheme_offsets(
            resx, resoff, rgl, newoff, ngl, 0, nsl, &loff)
        woff += lnew

        cur_count += 1

        rpos = pos + ogl
        pos = _replace_find_pos_uxx(
            selfx, sl, sgl, oldx, lold, ogl, selfoff, roff)
        if pos == -1 or (count > 0 and cur_count == count):
            break

        if lplus > 0 and cur_count >= reserve:
            reserve *= 2
            PyUnicode_Resize(&pres, sl + lplus * reserve)
            resx = <uintXX_t *> _PyUnicode_DATA(pres)
            resoff = <uint32_t *> PyMem_Realloc(resoff,
                sizeof(uint32_t) * (sl + 1 + lplus * reserve))

        off = selfoff[pos]

    rem = sl - roff
    if rem > 0:
        _copy_off_uxx(resx, woff, selfx, roff, rem)
        rgl += _replace_concat_grapheme_offsets(
            resx, resoff, rgl, selfoff, sgl, rpos, rem, &loff)
        roff += rem
        woff += rem
    resoff[rgl] = woff

    PyUnicode_Resize(&pres, woff)
    resx = <uintXX_t *> _PyUnicode_DATA(pres)

    if rgl != sl + 1 + lplus * reserve:
        resoff = <uint32_t *> PyMem_Realloc(resoff,
                                            sizeof(uint32_t) * (rgl + 1))

    if maybe_crunch:
        pres = maybe_down_size(pres, resx, woff)

    cdef graphemes g = graphemes.__new__(graphemes)
    g.ustr = _as_str_object(pres)
    g.off = resoff
    g.gl = rgl
    g.sl = woff
    return g


cdef inline uint32_t _replace_concat_grapheme_offsets(
     uintXX_t *ch_ustr, uint32_t *off, uint32_t gl,
     uint32_t *aoff, uint32_t apos, uint32_t arpos, uint32_t asl,
     uint32_t *ploff) noexcept:
    cdef uint32_t loff = ploff[0]
    cdef uint32_t agl = apos - arpos
    if asl == 0:
        return 0
    ploff[0] = loff + asl
    if loff == 0 or _will_break(ch_ustr, off[gl - 1], loff):
        _offcopy(&off[gl], &aoff[arpos], agl, loff - aoff[arpos])
        return agl
    return _recalc_appended_offsets(ch_ustr, off, gl, asl, loff)



cdef inline Py_ssize_t _lrfind_dispatch(
     graphemes self, object sub, int direction,
     Py_ssize_t start, Py_ssize_t end, bint partial) except -2:
    if isinstance(sub, str):
        return _lrfind_str(self, <str> sub, direction, start, end, partial)
    elif isinstance(sub, graphemes):
        return _lrfind_graphemes(self, <graphemes> sub, direction,
                                 start, end, partial)
    else:
        raise TypeError("must be graphemes or str, not %s"
                        % type(sub).__name__)


cdef inline Py_ssize_t _lrfind_str(graphemes self, unicode sub, int direction,
                                   Py_ssize_t start, Py_ssize_t end,
                                   bint partial) noexcept:
    PySlice_AdjustIndices(self.gl, &start, &end, 1)
    return _lrfind_unsafe(self, sub, UINT32_MAX, direction,
                          start, end, partial)


cdef inline Py_ssize_t _lrfind_graphemes(
     graphemes self, graphemes sub, int direction,
     Py_ssize_t start, Py_ssize_t end, bint partial) noexcept:
    PySlice_AdjustIndices(self.gl, &start, &end, 1)
    return _lrfind_unsafe(self, sub.ustr, sub.gl, direction,
                          start, end, partial)


cdef inline Py_ssize_t _lrfind_unsafe(
     graphemes self, unicode sub, uint32_t subgl, int direction,
     Py_ssize_t start, Py_ssize_t end, bint partial) noexcept:

    cdef Py_ssize_t ustart = self.off[start], uend = self.off[end]

    if PyUnicode_GET_LENGTH(sub) == 0:
        return start if direction > 0 else end

    if partial:
        return _off_to_pos_unsafe(self,
                                  PyUnicode_Find(self.ustr, sub,
                                                 ustart, uend, direction))

    if PyUnicode_KIND(sub) > PyUnicode_KIND(self.ustr):
        return -1

    if PyUnicode_KIND(self.ustr) == PyUnicode_1BYTE_KIND:
        return _lrfind_unsafe_1byte(self, sub, direction,
                                    ustart, uend)

    if subgl == UINT32_MAX:
        subgl = grapheme_len(sub)
    return _lrfind_unsafe_mbyte(self, sub, subgl, direction,
                                ustart, uend)


cdef inline Py_ssize_t _lrfind_unsafe_1byte(
     graphemes self, unicode sub, int direction,
     Py_ssize_t ustart, Py_ssize_t uend) noexcept:
    cdef uint32_t lsub = PyUnicode_GET_LENGTH(sub)
    cdef uint8_t *sub8 = <uint8_t *> PyUnicode_DATA(sub)
    cdef uint8_t *self8 = <uint8_t *> PyUnicode_DATA(self.ustr)
    cdef uint8_t lch = sub8[lsub - 1]

    cdef Py_ssize_t find_off = 0
    cdef Py_ssize_t find_pos_off = 0, find_pos_len = 0
    cdef uint32_t find_pos = 0

    while True:
        find_off = PyUnicode_Find(self.ustr, sub, ustart, uend, direction)
        if find_off == -1:
            return -1
        find_pos = _off_to_pos_unsafe(self, find_off)
        find_pos_off = self.off[find_pos]

        if (find_pos_off == find_off
            and (lch != 13 or lsub + find_off >= self.sl
                 or self8[lsub + find_off] != 10)):
            return find_pos

        if direction > 0:
            ustart = find_off + lsub
            if ustart >= uend:
                return -1
        else:
            uend = find_off - lsub + 1
            if ustart >= uend:
                return -1


cdef inline Py_ssize_t _lrfind_unsafe_mbyte(
     graphemes self, unicode sub, uint32_t subgl, int direction,
     Py_ssize_t ustart, Py_ssize_t uend) noexcept:
    cdef uint32_t lsub = PyUnicode_GET_LENGTH(sub)
    cdef Py_ssize_t find_off = 0
    cdef Py_ssize_t find_pos_off = 0, find_pos_len = 0
    cdef uint32_t find_pos = 0

    while True:
        find_off = PyUnicode_Find(self.ustr, sub, ustart, uend, direction)
        if find_off == -1:
            return -1
        find_pos = _off_to_pos_unsafe(self, find_off)
        find_pos_off = self.off[find_pos]

        if find_pos_off == find_off:
            if (lsub + find_off >= self.sl
                or (find_pos + subgl <= self.gl
                    and self.off[find_pos + subgl] == find_off + lsub)):
                return find_pos

        if direction > 0:
            ustart = find_off + lsub
            if ustart >= uend:
                return -1
        else:
            uend = find_off - lsub + 1
            if ustart >= uend:
                return -1


cdef inline Py_ssize_t _count(
     graphemes self, object sub,
     Py_ssize_t start, Py_ssize_t end, bint partial) except -1:
    PySlice_AdjustIndices(self.gl, &start, &end, 1)
    if isinstance(sub, str):
        return _count_unsafe(self, <str> sub, UINT32_MAX, start, end, partial)
    elif isinstance(sub, graphemes):
        return _count_unsafe(self, (<graphemes> sub).ustr,
                             (<graphemes> sub).gl, start, end, partial)
    else:
        raise TypeError("must be graphemes or str, not %s"
                        % type(sub).__name__)


cdef inline Py_ssize_t _count_unsafe(
     graphemes self, unicode sub, uint32_t subgl,
     Py_ssize_t start, Py_ssize_t end, bint partial) noexcept:

    cdef Py_ssize_t ustart = self.off[start], uend = self.off[end]

    if PyUnicode_GET_LENGTH(sub) == 0:
        return end - start + 1

    if partial:
        return PyUnicode_Count(self.ustr, sub, ustart, uend)

    if PyUnicode_KIND(sub) > PyUnicode_KIND(self.ustr):
        return 0

    if PyUnicode_KIND(self.ustr) == PyUnicode_1BYTE_KIND:
        return _count_unsafe_1byte(self, sub, ustart, uend)

    if subgl == UINT32_MAX:
        subgl = grapheme_len(sub)
    return _count_unsafe_mbyte(self, sub, subgl, ustart, uend)


cdef inline Py_ssize_t _count_unsafe_1byte(
     graphemes self, unicode sub,
     Py_ssize_t ustart, Py_ssize_t uend) noexcept:
    cdef uint32_t lsub = PyUnicode_GET_LENGTH(sub)
    cdef uint8_t *sub8 = <uint8_t *> PyUnicode_DATA(sub)
    cdef uint8_t *self8 = <uint8_t *> PyUnicode_DATA(self.ustr)
    cdef uint8_t fch = sub8[0]
    cdef uint8_t lch = sub8[lsub - 1]

    if (fch > 13 and lch > 13 or
         (fch != 13 and fch != 10 and lch != 13 and lch != 10)):
        return PyUnicode_Count(self.ustr, sub, ustart, uend)

    cdef Py_ssize_t find_off = 0
    cdef Py_ssize_t find_pos_off = 0, find_pos_len = 0
    cdef uint32_t find_pos = 0

    cdef Py_ssize_t count = 0

    while True:
        find_off = PyUnicode_Find(self.ustr, sub, ustart, uend, 1)
        if find_off == -1:
            return count
        find_pos = _off_to_pos_unsafe(self, find_off)
        find_pos_off = self.off[find_pos]

        if (find_pos_off == find_off
            and (lch != 13 or lsub + find_off >= self.sl
                 or self8[lsub + find_off] != 10)):
            count += 1

        ustart = find_off + lsub
        if ustart >= uend:
            return count


cdef inline Py_ssize_t _count_unsafe_mbyte(
     graphemes self, unicode sub, uint32_t subgl,
     Py_ssize_t ustart, Py_ssize_t uend) noexcept:
    cdef uint32_t lsub = PyUnicode_GET_LENGTH(sub)
    cdef Py_ssize_t find_off = 0
    cdef Py_ssize_t find_pos_off = 0, find_pos_len = 0
    cdef uint32_t find_pos = 0

    cdef Py_ssize_t count = 0

    while True:
        find_off = PyUnicode_Find(self.ustr, sub, ustart, uend, 1)
        if find_off == -1:
            return count
        find_pos = _off_to_pos_unsafe(self, find_off)
        find_pos_off = self.off[find_pos]

        if find_pos_off == find_off:
            if (lsub + find_off >= self.sl
                or (find_pos + subgl <= self.gl
                    and self.off[find_pos + subgl] == find_off + lsub)):
                count += 1

        ustart = find_off + lsub
        if ustart >= uend:
            return count


cdef inline unicode _lrjust(graphemes self, Py_ssize_t width, int side,
                            unicode fillchar, bint wcwidth):
    cdef Py_ssize_t sw = wcswidth(self.ustr) if wcwidth else self.ustr.gl
    if width <= sw:
        return self.ustr
    cdef Py_ssize_t wjust = self.sl + width - sw
    return (self.ustr.ljust(wjust, fillchar) if side < 0
            else (self.ustr.rjust(wjust, fillchar) if side > 0
                  else self.ustr.center(wjust, fillchar)))


cdef inline uint32_t _off_to_pos_unsafe(graphemes self, uint32_t off) noexcept:
    cdef uint32_t pos_lo = 0, pos_mid = 0, pos_hi = self.gl
    cdef uint32_t off_mid = 0, off_mid_hi = 0
    pos_mid = off
    if pos_mid >= self.gl:
        pos_mid = self.gl - 1
    while pos_lo < pos_hi:
        off_mid = self.off[pos_mid]
        off_mid_hi = self.off[pos_mid + 1]
        if off >= off_mid_hi:
            pos_lo = pos_mid + 1
        else:
            if off >= off_mid:
                return pos_mid
            pos_hi = pos_mid
        pos_mid = (pos_lo + pos_hi) >> 1
    return pos_mid


cdef inline unicode _slice(graphemes self, Py_ssize_t pos, Py_ssize_t end):
    if pos < 0:
        pos += self.gl
        if pos < 0:
            pos = 0
    elif pos >= self.gl:
        return ''
    if end < 0:
        end += self.gl
        if end < 0:
            end = 0
    if end <= pos:
        return ''
    if end >= self.gl:
        end = self.gl
        if pos == 0:
            return self.ustr

    cdef int kind = PyUnicode_KIND(self.ustr)
    cdef uint32_t off_pos = self.off[pos], off_end = self.off[end]
    cdef uint8_t *data = <uint8_t *> PyUnicode_DATA(self.ustr) + off_pos * kind
    return PyUnicode_FromKindAndData(kind, data, off_end - off_pos)


cdef inline unicode _slice_unsafe(graphemes self,
                                  Py_ssize_t pos, Py_ssize_t end):
    cdef int kind = PyUnicode_KIND(self.ustr)
    cdef uint32_t off_pos = self.off[pos], off_end = self.off[end]
    cdef uint8_t *data = <uint8_t *> PyUnicode_DATA(self.ustr) + off_pos * kind
    return PyUnicode_FromKindAndData(kind, data, off_end - off_pos)


cpdef inline graphemes _gslice(graphemes self,
                               Py_ssize_t pos, Py_ssize_t end,
                               Py_ssize_t step):
    if step != 1:
        return _gslice_hard(self, pos, end, step)

    if pos < 0:
        pos += self.gl
        if pos < 0:
            pos = 0
    elif pos >= self.gl:
        return _EMPTY_GRAPHEME
    if end < 0:
        end += self.gl
        if end < 0:
            end = 0
    if end <= pos:
        return _EMPTY_GRAPHEME
    if end >= self.gl:
        end = self.gl
        if pos == 0:
            return self

    cdef int kind = PyUnicode_KIND(self.ustr)
    cdef uint32_t off_pos = self.off[pos], off_end = self.off[end]
    cdef uint32_t sl = off_end - off_pos
    cdef uint32_t gl = end - pos
    cdef uint8_t *data = <uint8_t *> PyUnicode_DATA(self.ustr) + off_pos * kind
    cdef unicode ustr = PyUnicode_FromKindAndData(kind, data,
                                                  off_end - off_pos)
    cdef uint32_t *off = <uint32_t *> PyMem_Malloc(sizeof(uint32_t)
                                                   * (gl + 1))
    _offcopy(off, self.off + pos, gl + 1, -off_pos)

    cdef graphemes g = graphemes.__new__(graphemes)
    g.ustr = ustr
    g.sl = sl
    g.off = off
    g.gl = gl
    return g


cpdef inline graphemes _gslice_hard(graphemes self,
                                    Py_ssize_t pos, Py_ssize_t end,
                                    Py_ssize_t step):
    if step < 0:
        if pos == PY_SSIZE_T_MIN:
            pos = PY_SSIZE_T_MAX
        if end == PY_SSIZE_T_MAX:
            end = PY_SSIZE_T_MIN
        return graphemes.from_str(_neg_stepped_slice(self, pos, end, step))
    else:
        return graphemes.from_str(_stepped_slice(self, pos, end, step))


cdef inline unicode _at(graphemes self, Py_ssize_t pos):
    if pos >= self.gl:
        raise IndexError("index %d out of bounds" % pos)
    if pos < 0:
        pos += self.gl
        if pos < 0:
            raise IndexError("index %d out of bounds" % (pos - self.gl))

    cdef PyObject *ustr = <PyObject *> self.ustr
    cdef int kind = _PyUnicode_KIND(ustr)
    cdef uint32_t off_pos = self.off[pos], l = self.off[pos + 1] - off_pos
    cdef uint8_t *data = <uint8_t *> _PyUnicode_DATA(ustr) + off_pos * kind
    if kind == 1:
        return get_latin1_unicode(data[0]) if l == 1 else _CR_LF
    else:
        return PyUnicode_FromKindAndData(kind, data, l)


cdef inline unicode _at_unsafe(graphemes self, Py_ssize_t pos):
    cdef PyObject *ustr = <PyObject *> self.ustr
    cdef int kind = _PyUnicode_KIND(ustr)
    cdef uint32_t off_pos = self.off[pos], l = self.off[pos + 1] - off_pos
    cdef uint8_t *data = <uint8_t *> _PyUnicode_DATA(ustr) + off_pos * kind
    if kind == 1:
        return get_latin1_unicode(data[0]) if l == 1 else _CR_LF
    else:
        return PyUnicode_FromKindAndData(kind, data, l)


cdef inline unicode _stepped_slice(graphemes self,
                                   Py_ssize_t pos, Py_ssize_t end,
                                   Py_ssize_t step):
    if step < 0:
        return _neg_stepped_slice(self, pos, end, step)

    if pos < 0:
        pos += self.gl
        if pos < 0:
            pos = 0
    elif pos >= self.gl:
        return ''
    if end < 0:
        end += self.gl
        if end < 0:
            end = 0
    elif end >= self.gl:
        end = self.gl
    if end <= pos:
        return ''

    cdef int uprop = uprop_from_unicode(self.ustr)
    cdef uint32_t l = _slice_size_fwd(self.off, pos, end, step)
    cdef PyObject *out = _PyUnicode_New_by_Uprop(l, uprop)
    if uprop == Uprop_ASCII:
        _slice_copy_fwd(_PyUnicode_DATA(out),
                        <uint8_t *> PyUnicode_DATA(self.ustr), self.off,
                        pos, end, step)
    elif uprop == Uprop_Latin1:
        _slice_copy_fwd(_PyUnicode_DATA(out),
                        <uint8_t *> PyUnicode_DATA(self.ustr), self.off,
                        pos, end, step)
        out = maybe_down_size(out, <uint8_t *> _PyUnicode_DATA(out), l)
    elif uprop == Uprop_2BYTE:
        _slice_copy_fwd(_PyUnicode_DATA(out),
                        <uint16_t *> PyUnicode_DATA(self.ustr), self.off,
                        pos, end, step)
        out = maybe_down_size(out, <uint16_t *> _PyUnicode_DATA(out), l)
    elif uprop == Uprop_4BYTE:
        _slice_copy_fwd(_PyUnicode_DATA(out),
                        <uint32_t *> PyUnicode_DATA(self.ustr), self.off,
                        pos, end, step)
        out = maybe_down_size(out, <uint32_t *> _PyUnicode_DATA(out), l)
    return (<unicode> out)


cdef inline unicode _neg_stepped_slice(graphemes self,
                                       Py_ssize_t pos, Py_ssize_t end,
                                       Py_ssize_t step):
    if end < 0:
        end += self.gl
        if end < 0:
            end = -1
    elif end >= self.gl:
        return ''
    if pos >= self.gl:
        if self.gl == 0:
            return ''
        pos = self.gl - 1
    elif pos < 0:
        pos += self.gl
        if pos < 0:
            return ''
    if end >= pos:
        return ''

    cdef int uprop = uprop_from_unicode(self.ustr)
    cdef uint32_t l = _slice_size_rev(self.off, pos, end, step)
    cdef PyObject *out = _PyUnicode_New_by_Uprop(l, uprop)
    if uprop == Uprop_ASCII:
        _slice_copy_rev(_PyUnicode_DATA(out),
                        <uint8_t *> PyUnicode_DATA(self.ustr), self.off,
                        pos, end, step)
    elif uprop == Uprop_Latin1:
        _slice_copy_rev(_PyUnicode_DATA(out),
                        <uint8_t *> PyUnicode_DATA(self.ustr), self.off,
                        pos, end, step)
        out = maybe_down_size(out, <uint8_t *> _PyUnicode_DATA(out), l)
    elif uprop == Uprop_2BYTE:
        _slice_copy_rev(_PyUnicode_DATA(out),
                        <uint16_t *> PyUnicode_DATA(self.ustr), self.off,
                        pos, end, step)
        out = maybe_down_size(out, <uint16_t *> _PyUnicode_DATA(out), l)
    elif uprop == Uprop_4BYTE:
        _slice_copy_rev(_PyUnicode_DATA(out),
                        <uint32_t *> PyUnicode_DATA(self.ustr), self.off,
                        pos, end, step)
        out = maybe_down_size(out, <uint32_t *> _PyUnicode_DATA(out), l)
    return (<unicode> out)


cdef inline uint32_t _slice_size_fwd(uint32_t *off,
                                     uint32_t pos, uint32_t end,
                                     uint32_t step):
    cdef uint32_t n_grapheme_chrs = 0

    while True:
        n_grapheme_chrs += off[pos + 1] - off[pos]
        pos += step
        if pos >= end:
            return n_grapheme_chrs


cdef inline void _slice_copy_fwd(void *dst, uintXX_t *src, uint32_t *off,
                                 uint32_t pos, uint32_t end,
                                 uint32_t step) noexcept:
    cdef uintXX_t *ddst = <uintXX_t *> dst
    cdef int sz = sizeof(uintXX_t)
    cdef uint32_t n_grapheme_chrs

    while True:
        n_grapheme_chrs = off[pos + 1] - off[pos]
        memcpy(ddst, src + off[pos], n_grapheme_chrs * sz)
        ddst += n_grapheme_chrs
        pos += step
        if pos >= end:
            return


cdef inline uint32_t _slice_size_rev(uint32_t *off,
                                     Py_ssize_t pos, Py_ssize_t end,
                                     Py_ssize_t step):
    cdef uint32_t n_grapheme_chrs = 0

    while True:
        n_grapheme_chrs += off[pos + 1] - off[pos]
        pos += step
        if pos <= end:
            return n_grapheme_chrs


cdef inline void _slice_copy_rev(void *dst, uintXX_t *src, uint32_t *off,
                                 Py_ssize_t pos, Py_ssize_t end,
                                 Py_ssize_t step) noexcept:
    cdef uintXX_t *ddst = <uintXX_t *> dst
    cdef int sz = sizeof(uintXX_t)
    cdef uint32_t n_grapheme_chrs

    while True:
        n_grapheme_chrs = off[pos + 1] - off[pos]
        memcpy(ddst, src + off[pos], n_grapheme_chrs * sz)
        ddst += n_grapheme_chrs
        pos += step
        if pos <= end:
            return


cdef inline graphemes _replicate_graphemes(graphemes self, uint32_t count):
    if count == 0 or self.sl == 0:
        return _EMPTY_GRAPHEME
    if count == 1:
        return self

    if <Py_ssize_t> self.sl * <Py_ssize_t> count >= UINT32_MAX:
        raise ValueError("The resulting graphemes string is too large")

    cdef int kind = PyUnicode_KIND(self.ustr)
    cdef uint16_t tran = grapheme_calc_tran(0, self.ustr,
                                            upos=self.off[self.gl - 1])
    cdef void *data = PyUnicode_DATA(self.ustr)
    cdef uint32_t left_ch = <uint32_t> PyUnicode_READ(kind, data, self.sl - 1)
    cdef uint32_t right_ch = <uint32_t> PyUnicode_READ(kind, data, 0)
    tran = grapheme_split_uint32(tran, left_ch, right_ch)

    if tran & 0x100 == 0:
        return _replicate_graphemes_hard(self, count)

    cdef graphemes out = graphemes.__new__(graphemes)
    out.ustr = self.ustr * count
    out.sl = self.sl * count
    out.gl = self.gl * count

    cdef uint32_t *off = <uint32_t *> PyMem_Malloc(sizeof(uint32_t)
                                                   * (out.gl + 1))
    cdef uint32_t i, out_idx = 0, out_off = 0
    off[0] = 0
    for i in range(count):
        _offcopy(&off[out_idx], &self.off[0], self.gl + 1, out_off)
        out_idx += self.gl
        out_off += self.sl

    out.off = off
    return out


cdef inline graphemes _replicate_graphemes_hard(graphemes self, uint32_t count):
    cdef graphemes g = _append_graphemes(self, self)
    if count == 2:
        return g

    if (PyUnicode_KIND(self.ustr) == PyUnicode_1BYTE_KIND
        or g.gl != 2 * self.gl - 1):
        return graphemes(self.ustr * count)

    cdef graphemes out = graphemes.__new__(graphemes)
    out.ustr = self.ustr * count
    out.sl = self.sl * count

    cdef uint32_t out_gl = self.gl + ((count - 1) * (self.gl - 1))
    out.gl = out_gl
    cdef uint32_t *off = <uint32_t *>PyMem_Malloc(sizeof(uint32_t) *
                                                  (out_gl + 1))
    _offcopy(&off[0], &self.off[0], self.gl - 1, 0)
    cdef uint32_t last_start_off = 0
    cdef uint32_t last_start_off_adjust = g.off[self.gl - 1]
    cdef uint32_t last_end_off = self.gl - 1
    cdef uint32_t i
    for i in range(1, count):
        _offcopy(&off[last_end_off], &g.off[self.gl - 1], self.gl,
                 last_start_off)
        last_start_off = (off[last_end_off + self.gl - 1]
                          - last_start_off_adjust)
        last_end_off += self.gl - 1
    off[last_end_off + 1] = off[last_end_off] + g.off[g.gl] - g.off[g.gl - 1]
    out.off = off
    return out


cdef class graphemes_byte_iter_fwd:
    cdef graphemes g
    cdef uint32_t i, l
    cdef uint8_t *data
    cdef uint32_t *off

    def __cinit__(self):
        self.i = 1
        self.l = 0

    def __iter__(self):
        return self

    def __next__(self):
        cdef uint32_t i = self.i, ch_l = 1, off_i = 0
        cdef uint32_t *off = self.off
        if i < self.l:
            self.i += 1
            off_i = off[i]
            ch_l = off[i + 1] - off_i
            return (get_latin1_unicode(self.data[off[i]]) if ch_l == 1
                    else _CR_LF)
        else:
            raise StopIteration


cdef graphemes_byte_iter_fwd _make_graphemes_byte_iter_fwd(graphemes g):
    cdef graphemes_byte_iter_fwd it = graphemes_byte_iter_fwd.__new__(
        graphemes_byte_iter_fwd)
    it.g = g
    it.data = <uint8_t *> PyUnicode_DATA(g.ustr)
    it.off = g.off
    it.i = 0
    it.l = g.gl
    return it


cdef class graphemes_byte_iter_rev:
    cdef graphemes g
    cdef uint32_t i
    cdef uint32_t *off
    cdef uint8_t *data

    def __cinit__(self):
        self.i = UINT32_MAX

    def __iter__(self):
        return self

    def __next__(self):
        cdef uint32_t i = self.i, ch_l = 1, off_i = 0
        cdef uint32_t *off = self.off
        if i != UINT32_MAX:
            self.i -= 1
            off_i = off[i]
            ch_l = off[i + 1] - off_i
            return (get_latin1_unicode(self.data[off[i]]) if ch_l == 1
                    else _CR_LF)
        else:
            raise StopIteration


cdef graphemes_byte_iter_rev _make_graphemes_byte_iter_rev(graphemes g):
    cdef graphemes_byte_iter_rev it = graphemes_byte_iter_rev.__new__(
        graphemes_byte_iter_rev)
    it.g = g
    it.data = <uint8_t *> PyUnicode_DATA(g.ustr)
    it.off = g.off
    it.i = <uint32_t> g.gl - 1
    return it


cdef class graphemes_2byte_iter_fwd:
    cdef graphemes g
    cdef uint32_t i, l
    cdef uint16_t *data
    cdef uint32_t *off

    def __cinit__(self):
        self.i = 1
        self.l = 0

    def __iter__(self):
        return self

    def __next__(self):
        cdef uint32_t i = self.i, ch_l = 1, off_i = 0
        cdef uint32_t *off = self.off
        if i < self.l:
            self.i += 1
            off_i = off[i]
            ch_l = off[i + 1] - off_i
            return PyUnicode_FromKindAndData(PyUnicode_2BYTE_KIND,
                                             &self.data[off_i], ch_l)
        else:
            raise StopIteration


cdef graphemes_2byte_iter_fwd _make_graphemes_2byte_iter_fwd(graphemes g):
    cdef graphemes_2byte_iter_fwd it = graphemes_2byte_iter_fwd.__new__(
        graphemes_2byte_iter_fwd)
    it.g = g
    it.data = <uint16_t *> PyUnicode_DATA(g.ustr)
    it.off = g.off
    it.i = 0
    it.l = g.gl
    return it


cdef class graphemes_2byte_iter_rev:
    cdef graphemes g
    cdef uint32_t i
    cdef uint32_t *off
    cdef uint16_t *data

    def __cinit__(self):
        self.i = UINT32_MAX

    def __iter__(self):
        return self

    def __next__(self):
        cdef uint32_t i = self.i, ch_l = 1, off_i = 0
        cdef uint32_t *off = self.off
        if i != UINT32_MAX:
            self.i -= 1
            off_i = off[i]
            ch_l = off[i + 1] - off_i
            return PyUnicode_FromKindAndData(PyUnicode_2BYTE_KIND,
                                             &self.data[off_i], ch_l)
        else:
            raise StopIteration


cdef graphemes_2byte_iter_rev _make_graphemes_2byte_iter_rev(graphemes g):
    cdef graphemes_2byte_iter_rev it = graphemes_2byte_iter_rev.__new__(
        graphemes_2byte_iter_rev)
    it.g = g
    it.data = <uint16_t *> PyUnicode_DATA(g.ustr)
    it.off = g.off
    it.i = <uint32_t> g.gl - 1
    return it


cdef class graphemes_4byte_iter_fwd:
    cdef graphemes g
    cdef uint32_t i, l
    cdef uint32_t *data
    cdef uint32_t *off

    def __cinit__(self):
        self.i = 1
        self.l = 0

    def __iter__(self):
        return self

    def __next__(self):
        cdef uint32_t i = self.i, ch_l = 1, off_i = 0
        cdef uint32_t *off = self.off
        if i < self.l:
            self.i += 1
            off_i = off[i]
            ch_l = off[i + 1] - off_i
            return PyUnicode_FromKindAndData(PyUnicode_4BYTE_KIND,
                                             &self.data[off_i], ch_l)
        else:
            raise StopIteration


cdef graphemes_4byte_iter_fwd _make_graphemes_4byte_iter_fwd(graphemes g):
    cdef graphemes_4byte_iter_fwd it = graphemes_4byte_iter_fwd.__new__(
        graphemes_4byte_iter_fwd)
    it.g = g
    it.data = <uint32_t *> PyUnicode_DATA(g.ustr)
    it.off = g.off
    it.i = 0
    it.l = g.gl
    return it


cdef class graphemes_4byte_iter_rev:
    cdef graphemes g
    cdef uint32_t i
    cdef uint32_t *off
    cdef uint32_t *data

    def __cinit__(self):
        self.i = UINT32_MAX

    def __iter__(self):
        return self

    def __next__(self):
        cdef uint32_t i = self.i, ch_l = 1, off_i = 0
        cdef uint32_t *off = self.off
        if i != UINT32_MAX:
            self.i -= 1
            off_i = off[i]
            ch_l = off[i + 1] - off_i
            return PyUnicode_FromKindAndData(PyUnicode_4BYTE_KIND,
                                             &self.data[off_i], ch_l)
        else:
            raise StopIteration


cdef graphemes_4byte_iter_rev _make_graphemes_4byte_iter_rev(graphemes g):
    cdef graphemes_4byte_iter_rev it = graphemes_4byte_iter_rev.__new__(
        graphemes_4byte_iter_rev)
    it.g = g
    it.data = <uint32_t *> PyUnicode_DATA(g.ustr)
    it.off = g.off
    it.i = <uint32_t> g.gl - 1
    return it


cdef class graphemes_offsets_iter:
    def __cinit__(self):
        self.i = 1
        self.l = 0

    def __iter__(self):
        return self

    def __next__(self):
        cdef uint32_t i = self.i, ch_l = 1, off_i = 0
        cdef uint32_t *off = self.off
        if i < self.l:
            self.i += 1
            return off[i]
        else:
            raise StopIteration


cdef graphemes_offsets_iter _make_graphemes_offsets_iter(graphemes g):
    cdef graphemes_offsets_iter it = graphemes_offsets_iter.__new__(
        graphemes_offsets_iter)
    it.g = g
    it.i = 0
    it.l = g.gl + 1
    it.off = g.off
    return it


cdef inline uint8_t *_copyout_1byte_ustr(uint8_t *ch_out_ustr8,
                                         PyObject *ustr) noexcept:
    cdef Py_ssize_t l = _PyUnicode_GET_LENGTH(ustr)
    memcpy(ch_out_ustr8, _PyUnicode_DATA(ustr), l)
    return ch_out_ustr8 + l


cdef inline uint8_t *_copyout_1byte_graphemes(uint8_t *ch_out_ustr8,
                                              PyObject *pg) noexcept:
    return _copyout_1byte_ustr(ch_out_ustr8, _graphemes_GET_USTR(pg))


cdef inline uint8_t *_copyout_1byte_ustr_or_graphemes(
     uint8_t *ch_out_ustr8, PyObject *ustr_or_pg) noexcept:
    return _copyout_1byte_ustr(ch_out_ustr8,
                               ustr_or_pg if _PyUnicode_Check(ustr_or_pg)
                               else _graphemes_GET_USTR(ustr_or_pg))


cdef inline void *_kk_copy_ustr(void *ch_out_ustr, int max_kind,
                                PyObject *ustr) noexcept:
    return kk_copy(ch_out_ustr, max_kind,
                   _PyUnicode_DATA(ustr), _PyUnicode_KIND(ustr),
                   _PyUnicode_GET_LENGTH(ustr))


cdef inline void *_kk_copy_graphemes(void *ch_out_ustr, int max_kind,
                                     PyObject *pg) noexcept:
    return _kk_copy_ustr(ch_out_ustr, max_kind, _graphemes_GET_USTR(pg))


cdef inline void *_kk_copy_ustr_or_graphemes(void *ch_out_ustr, int max_kind,
                                             PyObject *ustr_or_pg) noexcept:
    return _kk_copy_ustr(ch_out_ustr, max_kind,
                         ustr_or_pg if _PyUnicode_Check(ustr_or_pg)
                         else _graphemes_GET_USTR(ustr_or_pg))


cdef extern from *:
    """
    # include <Python.h>

    # define _as_str_object(x) (x)
    # define _as_graphemes_object(x) (x)
    """
    unicode _as_str_object(PyObject *o)
    graphemes _as_graphemes_object(PyObject *o)
    void _Py_DECREF "Py_DECREF" (PyObject *o)
    long _PyObject_Hash "PyObject_Hash" (PyObject *o)
