# (C) 2024 !ZAJC!/GDS
# SPDX-License-Identifier: 0BSD
from setuptools import setup, Extension

setup(
    name='ugrapheme',
    ext_modules=[Extension("ugrapheme.alloc", sources=["ugrapheme/alloc.pyx"]),
                 Extension("ugrapheme.graphemes", sources=["ugrapheme/graphemes.pyx"]),
                 Extension("ugrapheme.iterate", sources=["ugrapheme/iterate.pyx"]),
                 Extension("ugrapheme.offsets", sources=["ugrapheme/offsets.pyx"]),
                 Extension("ugrapheme.justify", sources=["ugrapheme/justify.pyx"]),
                 Extension("ugrapheme.ugrapheme", sources=["ugrapheme/ugrapheme.pyx"])],
    package_data={'ugrapheme': ['ugrapheme/*.pxd', 'ugrapheme/*.pyx']}
)
