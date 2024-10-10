#cython: language_level=3
from libc.stdint cimport uint8_t


cdef extern from *:
    """
    # include <stdint.h>
    static uint8_t _PREP_HI_PHY[] = {
10,8,8,8,11,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,12,8,8,
13,8,14,8,8,8,8,8,8,8,8,8,8,15,8,8,8,8,8,8,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,255,
255,255,255,255,255,255,255,1,0,1,0,0,0,0,0,96,0,0,0,0,0,0,0,20,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,32,128,31,0,0,0,0,0,0,0,2,0,0,0,0,0,0,32,0,0,0,0,0,0,0
    };
    static size_t _PREP_HI_MINVAL = 0x110bd;
    static size_t _PREP_HI_MAXVAL = 0x11f02;
    static uint8_t _PREP_LO_PHY[] = {
17,15,15,15,15,15,18,15,19,15,15,15,15,15,15,15,15,15,15,15,20,15,15,21,15,15,
15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,
15,15,15,15,15,15,22,0,0,0,0,0,255,255,255,255,63,0,0,0,0,0,0,32,0,128,0,0,0,
0,3,0,4,0,0,0,0,64,0,0
    };
    static size_t _PREP_LO_MINVAL = 0x600;
    static size_t _PREP_LO_MAXVAL = 0xd4e;
    """
    cdef uint8_t *_PREP_HI_PHY
    cdef size_t _PREP_HI_MINVAL, _PREP_HI_MAXVAL
    cdef uint8_t *_PREP_LO_PHY
    cdef size_t _PREP_LO_MINVAL, _PREP_LO_MAXVAL
