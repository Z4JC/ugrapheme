#cython: language_level=3
# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD/

from libc.stdint cimport uint32_t
from cpython.unicode cimport (PyUnicode_1BYTE_KIND, PyUnicode_2BYTE_KIND,
                              PyUnicode_4BYTE_KIND)


assert PyUnicode_1BYTE_KIND == 1
assert PyUnicode_2BYTE_KIND == 2
assert PyUnicode_4BYTE_KIND == 4


cdef extern from *:
    """
    # include <stdint.h>
    # include <string.h>
    # include <Python.h>


    static inline void *kk_copy(void *dst, int kind_dst,
                                void *src, int kind_src,
                                uint32_t l) {
      if(kind_dst == kind_src) {
        memcpy(dst, src, kind_dst * l);
        return (uint8_t *)dst + kind_dst * l;
      }
      if(kind_dst == 2) {
        uint16_t *dst16 = (uint16_t *) dst;
        uint8_t *src8 = (uint8_t *) src;
        for (uint32_t i = 0; i < l; ++i)
          dst16[i] = src8[i];
        return dst16 + l;
      }
      uint32_t *dst32 = (uint32_t *) dst;
      if (kind_src == 1) {
        uint8_t *src8 = (uint8_t *) src;
        for (uint32_t i = 0; i < l; ++i)
          dst32[i] = src8[i];
        return dst32 + l;
      }
      uint16_t *src16 = (uint16_t *) src;
      for (uint32_t i = 0; i < l; ++i)
        dst32[i] = src16[i];
      return dst32 + l;
    }

    static inline void *kk_copy_off(void *dst, uint32_t off_dst, int kind_dst,
                                    void *src, uint32_t off_src, int kind_src,
                                    uint32_t l) {
      if(kind_dst == kind_src) {
        memcpy((uint8_t *) dst + kind_dst * off_dst,
               (uint8_t *) src + kind_dst * off_src, kind_dst * l);
        return (uint8_t *)dst + kind_dst * l;
      }
      if(kind_dst == 2) {
        uint16_t *dst16 = (uint16_t *) dst + off_dst;
        uint8_t *src8 = (uint8_t *) src + off_src;
        for (uint32_t i = 0; i < l; ++i)
          dst16[i] = src8[i];
        return dst16 + l;
      }
      uint32_t *dst32 = (uint32_t *) dst + off_dst;
      if (kind_src == 1) {
        uint8_t *src8 = (uint8_t *) src + off_src;
        for (uint32_t i = 0; i < l; ++i)
          dst32[i] = src8[i];
        return dst32 + l;
      }
      uint16_t *src16 = (uint16_t *) src + off_src;
      for (uint32_t i = 0; i < l; ++i)
        dst32[i] = src16[i];
      return dst32 + l;
    }
    """
    void *kk_copy(void *dst, int kind_dst, void *src, int kind_src,
                  uint32_t l) noexcept
    void *kk_copy_off(void *dst, uint32_t off_dst, int kind_dst,
                      void *src, uint32_t off_src, int kind_src,
                      uint32_t l) noexcept
