.PHONY: all build build-debug clean clean-build clean-venv test

all: build venv
	@:

build: venv
	DEBUG=$(DEBUG) venv/bin/python3 setup.py build_ext --inplace

build-debug: override DEBUG=1
build-debug: build ;

clean: clean-venv clean-build
	@:

clean-venv:
	rm -rf venv

clean-build:
	rm -rf build

test: build
	venv/bin/pytest

venv:
	python3 -mvenv venv
	venv/bin/pip install setuptools Cython uwcwidth pytest
