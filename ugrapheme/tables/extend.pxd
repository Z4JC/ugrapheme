#cython: language_level=3
from libc.stdint cimport uint8_t


cdef extern from *:
    """
    static uint8_t _EXT_LO1_PHY[] = {
24,25,23,23,23,23,26,23,23,23,27,28,29,30,23,31,32,33,34,35,36,37,38,39,40,41,
42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,
68,69,70,23,23,23,23,23,23,23,23,23,23,71,23,23,23,23,23,23,23,23,23,23,23,23,
23,23,72,73,74,75,76,23,77,23,78,23,23,23,79,80,81,82,83,84,85,86,87,23,23,88,
23,23,23,24,23,23,23,23,23,23,23,23,89,23,23,90,23,23,23,23,23,23,23,23,23,23,
23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,
23,23,23,23,23,23,23,23,23,23,23,91,23,92,23,93,23,23,23,23,23,23,23,23,94,23,
95,0,0,0,0,0,0,0,0,0,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
0,0,248,3,0,0,0,0,0,0,0,0,254,255,255,255,255,191,182,0,0,0,0,0,0,0,0,0,255,7,
0,0,0,0,0,248,255,255,0,0,1,0,0,0,192,159,159,61,0,0,0,0,2,0,0,0,255,255,255,
7,0,0,0,0,0,0,0,0,0,0,192,255,1,0,0,0,0,0,0,248,15,32,0,0,192,251,239,62,0,0,
0,0,0,14,0,0,0,0,0,0,0,255,0,0,0,0,0,252,255,255,251,255,255,255,7,0,0,0,0,0,
0,20,254,33,254,0,12,0,0,0,2,0,0,0,0,0,0,80,30,32,128,0,12,0,0,64,6,0,0,0,0,0,
0,16,134,57,2,0,0,0,35,0,6,0,0,0,0,0,0,16,190,33,0,0,12,0,0,252,2,0,0,0,0,0,0,
208,30,32,224,0,12,0,0,0,4,0,0,0,0,0,0,64,1,32,128,0,0,0,0,0,17,0,0,0,0,0,0,
208,193,61,96,0,12,0,0,0,2,0,0,0,0,0,0,144,68,48,96,0,12,0,0,0,3,0,0,0,0,0,0,
88,30,32,128,0,12,0,0,0,2,0,0,0,0,0,0,0,0,132,92,128,0,0,0,0,0,0,0,0,0,0,242,
7,128,127,0,0,0,0,0,0,0,0,0,0,0,0,242,31,0,127,0,0,0,0,0,0,0,0,0,3,0,0,160,2,
0,0,0,0,0,0,254,127,223,224,255,254,255,255,255,31,64,0,0,0,0,0,0,0,0,0,0,0,0,
224,253,102,0,0,0,195,1,0,30,0,100,32,0,32,0,0,0,0,0,0,0,224,0,0,0,0,0,0,28,0,
0,0,12,0,0,0,12,0,0,0,12,0,0,0,0,0,0,0,176,63,64,254,15,32,0,0,0,0,0,184,0,0,
0,0,0,0,96,0,0,0,0,2,0,0,0,0,0,0,135,1,4,14,0,0,128,9,0,0,0,0,0,0,64,127,229,
31,248,159,0,0,0,0,0,0,255,255,255,127,0,0,0,0,0,0,15,0,0,0,0,0,240,23,4,0,0,
0,0,248,15,0,3,0,0,0,60,59,0,0,0,0,0,0,64,163,3,0,0,0,0,0,0,240,207,0,0,0,247,
255,253,33,16,3,0,16,0,0,0,0,0,0,0,0,255,255,255,255,1,0,0,0,0,0,0,128,3,0,0,
0,0,0,0,0,0,128,0,0,0,0,255,255,255,255,0,0,0,0,0,252,0,0,0,0,0,6,0,0,0,0
    };
    static size_t _EXT_LO1_MINVAL = 0x300;
    static size_t _EXT_LO1_MAXVAL = 0x309a;

    static uint8_t _EXT_LO2_PHY[] = {
44,45,42,46,47,48,49,50,51,52,53,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,54,42,42,42,42,42,55,42,42,56,42,42,42,
42,57,58,42,59,42,42,42,42,42,42,42,42,42,42,42,42,60,61,42,42,42,42,62,42,42,
63,64,65,66,67,68,69,70,71,72,73,74,75,42,76,77,78,79,42,80,42,81,82,83,84,42,
42,85,86,87,88,42,42,89,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,90,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,91,42,42,42,42,42,42,42,92,93,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,94,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,95,42,42,42,96,
97,98,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,99,100,42,42,42,42,42,42,
42,42,42,42,101,102,103,42,42,104,105,42,42,106,107,42,42,42,42,42,42,108,109,
42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,110,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,255,255,255,255,255,255,255,255,255,255,255,255,
255,255,255,255,239,127,0,0,0,128,1,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,136,16,0,0,192,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,96,0,0,0,
254,255,7,0,1,0,0,0,128,127,0,0,0,255,7,0,0,0,0,0,14,0,0,0,0,0,144,103,0,0,0,
0,64,0,0,0,0,0,0,0,0,252,204,0,16,32,0,0,0,0,0,32,0,0,0,0,0,0,58,131,5,0,0,0,
0,96,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,64,66,0,0,
0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,254,255,1,0,254,255,1,0,0,0,0,0,0,0,0,0,0,0,
0,128,1,0,0,0,0,0,0,0,0,0,0,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,2,0,128,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,220,224,1,0,0,0,0,14,1,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,192,0,0,0,0,0,0,0,224,1,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,48,0,0,0,0,0,0,0,0,0,192,1,0,0,0,0,0,0,0,128,255,3,0,0,0,0,0,120,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,254,255,0,0,0,0,0,50,0,7,0,0,0,0,
0,240,12,8,0,0,0,0,0,0,0,14,0,0,0,0,223,63,0,0,0,0,0,0,0,16,0,6,0,0,0,0,0,128,
255,0,60,1,0,0,0,0,0,0,0,0,0,0,0,167,129,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,241,15,0,0,6,0,0,0,0,0,0,176,2,0,0,1,128,63,62,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,254,185,0,0,128,0,0,0,0,0,0,0,0,0,0,242,75,27,0,0,0,0,0,
0,0,0,0,0,0,0,0,121,96,3,0,0,96,0,0,0,0,0,0,0,0,0,0,240,79,3,0,0,0,0,0,0,0,0,
0,0,0,0,80,126,1,0,0,0,0,0,0,0,0,0,0,0,192,121,31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,255,13,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,176,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,224,25,2,0,0,0,252,15,0,0,0,0,240,243,0,1,252,28,0,0,0,0,0,248,255,6,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,254,126,1,0,0,0,0,0,0,0,0,0,248,255,255,249,
219,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,252,104,127,1,0,0,0,0,0,0,0,0,70,1,0,0,0,0,
0,0,0,0,0,0,48,0,6,0,0,0,0,0,128,15,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,255,
127,0,0,0,62,0,0,0,0,0,0,0,254,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,
0,0,0,0,15,0,0,0,0,0,0,0,0,0,32,0,0,0,0,0,0,192,0,0,0,0,0,0,0,0,0,0,0,0,254,
255,255,255,255,127,254,255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,64,135,
15,240,207,31,0,0,0,120,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,56,0,0,0,0,0,0,0,
254,255,255,255,255,255,255,240,255,255,255,255,255,63,64,0,32,0,0,240,253,
255,1,0,0,0,0,0,0,0,0,0,254,254,255,243,183,15,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,254,0,0,0,0,0,0,0,0,0,0,0,0,0,0,128,0,0,0,0,
0,0,0,224,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,224,1,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,254,0,0,0,0,0,0,0,0,0,0,
0,0,0,224,15,0,0,0,0,0,240,1,0,0,0,0,0,0,0,0,0,0,0,0,0
    };
    static size_t _EXT_LO2_MINVAL = 0xa66f;
    static size_t _EXT_LO2_MAXVAL = 0x1f3ff;

    static uint8_t _EXT_HI_PHY[] = {
5,5,5,4,4,4,4,5,5,5,5,5,5,5,6,0,0,0,0,0,255,255,255,255,255,255,0,0
    };
    static size_t _EXT_HI_MINVAL = 0xe0020;
    static size_t _EXT_HI_MAXVAL = 0xe01ef;
    """
    cdef uint8_t *_EXT_LO1_PHY
    cdef size_t _EXT_LO1_MINVAL, _EXT_LO1_MAXVAL
    cdef uint8_t *_EXT_LO2_PHY
    cdef size_t _EXT_LO2_MINVAL, _EXT_LO2_MAXVAL
    cdef uint8_t *_EXT_HI_PHY
    cdef size_t _EXT_HI_MINVAL, _EXT_HI_MAXVAL
