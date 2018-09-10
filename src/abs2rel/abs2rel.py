#!/usr/bin/env python3

# Copyright 2018 Charles Daniels

#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:

#  1. Redistributions of source code must retain the above copyright notice,
#  this list of conditions and the following disclaimer.

#  2. Redistributions in binary form must reproduce the above copyright notice,
#  this list of conditions and the following disclaimer in the documentation
#  and/or other materials provided with the distribution.

#  3. Neither the name of the copyright holder nor the names of its
#  contributors may be used to endorse or promote products derived from this
#  software without specific prior written permission.

#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.


version = "0.0.1"

descr = """
Convert a list of paths piped in on standard in to be relative to a given
path (./ by default). This is useful when dealing with other scripts that
require relative paths.
"""

import os
import argparse
import sys

parser = argparse.ArgumentParser(description=descr)

parser.add_argument('--version', action='version', version=version)

parser.add_argument("--input", "-i", default=sys.stdin, help="Input file to" +
                    " read the (newline-delimited) list of files from." +
                    " (default: standard input)")

parser.add_argument("--output", "-o", default=sys.stdout, help="Output file " +
                    "to write converted paths to (newline-delimited). " +
                    "Note that his file will be overwritten, not appended to" +
                    ". (default: standard out)")

parser.add_argument("--relative_to", "-r", default=os.getcwd(), help="" +
                    "Path to make the input paths relative to. (default: " +
                    "current working directory)")

parser.add_argument("paths", nargs="*", help="If standard in is a tty, used" +
                    " as paths to convert, otherwise ignored.")

args = parser.parse_args()


if args.input is sys.stdin:
    ifhandle = args.input
else:
    ifhandle = open(args.input, 'r')

ofhandle = None
if args.output is sys.stdout:
    ofhandle = args.output
else:
    ofhandle = open(args.output, 'w')

iterate_over = None
if ifhandle.isatty():
    iterate_over = args.paths
else:
    iterate_over = ifhandle

for ipath in iterate_over:
    opath = os.path.relpath(ipath, args.relative_to).strip()
    sys.stdout.write("{}\n".format(opath))

# cleanup
ofhandle.flush()
ofhandle.close()
ifhandle.close()
