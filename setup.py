# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
import os
import platform

from setuptools import setup, Extension


DEBUG=(os.getenv('DEBUG') or '').strip().lower() in ['1', 'y', 'true']
MSVC=(platform.platform().startswith('Windows') and
      platform.python_compiler().startswith('MS'))
COMPILE_ARGS=[] if MSVC else (["-g", "-O0", "-UNDEBUG"] if DEBUG else ["-O3"])


def ugrapheme_ext(module, pyx_file):
    return Extension(module,
                     sources=[pyx_file],
                     extra_compile_args=COMPILE_ARGS)


setup(
    name='ugrapheme',
    ext_modules=[ugrapheme_ext("ugrapheme.alloc", "ugrapheme/alloc.pyx"),
                 ugrapheme_ext("ugrapheme.graphemes", "ugrapheme/graphemes.pyx"),
                 ugrapheme_ext("ugrapheme.iterate", "ugrapheme/iterate.pyx"),
                 ugrapheme_ext("ugrapheme.offsets", "ugrapheme/offsets.pyx"),
                 ugrapheme_ext("ugrapheme.justify", "ugrapheme/justify.pyx"),
                 ugrapheme_ext("ugrapheme.ugrapheme", "ugrapheme/ugrapheme.pyx")],
    package_data={'ugrapheme': ['*.pxd', '*.pyx', 'tables/*.pxd', 'tables/*.pyx']},
    include_package_data=True
)
