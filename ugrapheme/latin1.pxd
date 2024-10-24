from libc.stdint cimport uint8_t


cdef extern from *:
    """
    # include <Python.h>

    # include <stdint.h>

    static PyObject *LATIN1[0x100];

    static inline void init_latin1(void) {
      for (int i = 0; i < 0x100; ++i) {
        uint8_t lchar = i;

        LATIN1[i] = PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, &lchar, 1);
        Py_INCREF(LATIN1[i]);
      }
    }

    static inline PyObject *get_latin1(uint8_t u8ch) {
      Py_INCREF(LATIN1[u8ch]);
      return LATIN1[u8ch];
    }

    static inline PyObject *get_latin1_unicode(uint8_t u8ch) {
      return get_latin1(u8ch);
    }
    """
    cdef void init_latin1() noexcept
    cdef object get_latin1(uint8_t u8ch) noexcept
    cdef unicode get_latin1_unicode(uint8_t u8ch) noexcept
