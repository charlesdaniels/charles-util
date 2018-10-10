# charles-util

## Contents


<!-- vim-markdown-toc GFM -->

* [Introduction](#introduction)
* [Future Plans](#future-plans)
* [Installation](#installation)
* [License](#license)
* [Release History](#release-history)
	* [charels-util R1](#charels-util-r1)
	* [charles-util R2](#charles-util-r2)
		* [Other Changes:](#other-changes)
	* [charles-util R3](#charles-util-r3)
		* [Other Changes:](#other-changes-1)
	* [charles-util R4](#charles-util-r4)
		* [Other Changes](#other-changes-2)
	* [charles-util R5](#charles-util-r5)
		* [Other Changes](#other-changes-3)

<!-- vim-markdown-toc -->

## Introduction

This is a collection of tools and utilities I have written which are large
enough to warrant packaging properly and writing man pages for, but not large
enough to make a dedicated project/repository/package worthwhile.

A reasonable effort is made to polish, test, and document these tools, but some
edge cases may not be handled gracefully, and portability to arbitrary
platforms is not guaranteed, although release are compiled as static executable
as much as possible to improve portability.

Note that the charles-util release number does not used semantic versioning -
this is because each tool is versioned individually (a changelog is recorded in
each tool's manpage). A charles-util release is simply a collection of the
constant tools at specific versions.

## Future Plans

* Testing methodology for individual tools where possible.
* TravisCI setup
* TravisCI Release Uploading
* Better man pages for pdfutil
* Refactoring for pdfutil

## Installation

See [INSTALL](./INSTALL).

## License

BSD 3-clause, See [LICENSE](./LICENSE).

## Release History

Each sub-section lists tools that have changed version since the previous
release, along with the version current as of the given release.

### charels-util R1

* abs2rel: 0.0.1
* bacchus: 0.0.1
* colortool: 0.0.1
* disavow: 0.0.1
* fieldify: 0.0.1
* get-ip: 0.0.1
* get-token: 0.0.1
* nios2-search: 0.0.1
* nios2-sh: 0.0.1
* pdfutil-combine: 0.0.1
* pdfutil-from-office: 0.0.1
* pdfutil-optimize: 0.0.1
* pdfutil-scrub: 0.0.1
* query-webpage: 0.0.1
* rtspman: 0.0.1
* swizzle: 0.0.2
* tagdump: 0.0.1
* tagsearch: 0.0.1

### charles-util R2

* get-token: 0.0.2

#### Other Changes:

* Builds for pyinstaller-ed python programs now use virtualenv.
* Releases no longer include src/ to reduce size.
* Release tarballs now include `charles-util` as a directory, rather than
  placing all included files under the top level.

### charles-util R3

* colortool: 1.0.0
* bytesh: 0.0.1
* fieldify: 0.1.0
* picobar: 0.0.1

#### Other Changes:

* `python3 -m virtualenv` is now used instead of `virtualenv` throughout the
  build system, to support versions of virtualenv installed via OS package
  managers.

### charles-util R4


#### Other Changes

* Fixed build-related issues relating to picobar which caused the ip block not
  to work in the compiled version. This happened sufficiently far into the R3
  release that R3 could not be revised.

* Updated INSTALL document with perl dependencies.

### charles-util R5

* picobar: 0.1.0
* colortool: 1.0.1

#### Other Changes

* Replace top-level `Makefile` with `build.sh` script, which allows a greater
  degree of configuration, such as disable `pp` or `pyinstaller`. This is to
  support installation on systems such as OpenBSD which don't have support from
  one or more of these. The new build script also correctly detects non-GNU
  versions of Make.

* pdfutil has been deprecated due to poor code quality.

* Fixed Makefile for `bytesh` to build on OpenBSD
