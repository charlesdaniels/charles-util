******************************
Documentation for ``cliptool``
******************************

.. contents::



Wrapper for interacting with various clipboard systems from the CLI.  On
macOS, this wraps pbcopy/pbpaste, and on Linux it wraps xclip. If neither is
available, it will fail over to using a temporary file in ``/tmp``, which may
be useful when used within other scripts.

Note that on Linux, this explicitly does not use the "X Clipboard" (the one
that uses middle mouse), but rather the one that uses ``<C-c>`` and
``<C-v>``. This should hold true for other systems that use Xorg/X11.


Syntax
======

::


     $1 . . . . if `copy` - copy standard input to the system clipboard
                if `get`  - output the system clipboard contents to stdout

    The following environment variables are checked to configure behaviour:

    CLIPTOOL_CLIPBOARD_MANAGER . . . if set, the specified clipboard manager
                                     will be used instead of following the
                                     above hierarchy. Note that the specified
                                     clipboard manager must be one of the
                                     supported ones, or the program will crash.


Author
======


Charles Daniels


License
=======


Copyright 2018 Charles Daniels

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 3. Neither the name of the copyright holder nor the names of its
 contributors may be used to endorse or promote products derived from this
 software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.










