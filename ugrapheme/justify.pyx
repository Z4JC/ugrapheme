#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD

from ugrapheme.ugrapheme cimport grapheme_len
from uwcwidth cimport wcswidth


cpdef unicode ljust(unicode ustr, Py_ssize_t width, unicode fillchar=' ',
                    wcwidth=True):
    """Return a left-justified string of length width.

    Padding is done using the specified fill character (default is a space).
    By default, ljust considers the printable width inside a terminal.
    With wcwidth=False, ljust only uses the total number of unicode codepoints
    to calculate the padding size, just like in standard python strings."""
    return _lrjust(ustr, width, -1, fillchar, wcwidth)


cpdef unicode rjust(unicode ustr, Py_ssize_t width, unicode fillchar=' ',
                    wcwidth=True):
    """Return a right-justified string of length width.

    Padding is done using the specified fill character (default is a space).
    By default, rjust considers the printable width inside a terminal.
    With wcwidth=False, rjust only uses the total number of unicode codepoints
    to calculate the padding size, just like in standard python strings."""
    return _lrjust(ustr, width, 1, fillchar, wcwidth)


cpdef unicode center(unicode ustr, Py_ssize_t width, unicode fillchar=' ',
                     wcwidth=True):
    """Return a centered string of length width.

    Padding is done using the specified fill character (default is a space).
    By default, center considers the printable width inside a terminal.
    With wcwidth=False, center only uses the total number of unicode
    codepoints to calculate the padding size, just like in standard python
    strings."""
    return _lrjust(ustr, width, 0, fillchar, wcwidth)


cdef inline unicode _lrjust(unicode ustr, Py_ssize_t width, int side,
                            unicode fillchar, wcwidth):
    cdef Py_ssize_t sw = wcswidth(ustr) if wcwidth else grapheme_len(ustr)
    if width <= sw:
        return ustr
    cdef Py_ssize_t wjust = len(ustr) + width - sw
    return (ustr.ljust(wjust, fillchar) if side < 0
            else (ustr.rjust(wjust, fillchar) if side > 0
                  else ustr.center(wjust, fillchar)))
