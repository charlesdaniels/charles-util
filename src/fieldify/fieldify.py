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


import argparse
import re
import sys

descr = """
This script consumes streaming data from standard in and splits it along a
regular expression, then replaces the splits with a set field separator.  By
default, it collapses whitespace-separated columns into tab-separated columns.
"""

version = "0.0.1"

def format_record(rec, r, ofs):
    """format_record

    Format the output of an entire record. The caller is expected to ensure
    that the partial records are not passed in.

    :param rec: record to format
    :param r: compiled regex to use for splitting in lieu of IFS
    :param ofs: output field separator
    """

    return ofs.join([x for x in r.split(rec) if x != ""])

def extract_records(s, irs):
    """extract_records

    Extract records from the string s along the irs delimiter, returning a
    tuple of the record list and any remainder. If irs is not present in s,
    then this function returns ([], s). The caller is expected to grantee that
    s is non-empty.

    :param s:
    :param irs:
    """

    if irs not in s:
        return ([], s)
    else:
        records = s.split(irs)
        return (records[:-1], records[-1])

def main():

    parser = argparse.ArgumentParser(description=descr)

    parser.add_argument('--version', action='version', version=version)

    parser.add_argument("--ofs", "-F", default='\t',
            help="Specify output field separator. (default: \\t)")

    parser.add_argument("--irs", "-f", default='\n',
            help="Override default input record separator. (default: \\n)")

    parser.add_argument("--ors", "-R", default='\n',
            help="Override default output record separator. (default: \\n)")

    parser.add_argument("--regex", "-r", default='\s',
            help="Specify regex to split with, in Python 3.X re format." +
            "This is used in lieu of an IFS. (default: \\s")

    parser.add_argument("--bufsize", "-b", default=4096, type=int,
            help="Override read buffer size. (default: 4096)")

    args = parser.parse_args()

    bufsize = args.bufsize
    buf = ""
    ofs = args.ofs
    regex = args.regex
    irs = args.irs
    ors = args.ors
    r = None

    try:
        r = re.compile(regex)
    except Exception as e:
        sys.stderr.write("ERROR: Invalid regex: {}\n".format(e))
        sys.exit(1)

    if bufsize < 16:
        sys.stderr.write("bufsize too small (< 16).\n")
        sys.exit(1)

    while True:
        buf_step = sys.stdin.read(bufsize)
        buf += buf_step

        if buf_step == '':
            # we are done reading
            if buf != '':
                # there is still text in the buffer
                sys.stdout.write(ors)
                sys.stdout.write(format_record(buf, r, ofs))
            break

        (records, buf) = extract_records(buf, irs)

        if len(records) == 0:
            continue

        for i in range(len(records)):
            sys.stdout.write(format_record(records[i], r, ofs))

            if i + 1 < len(records):
                # avoid emitting a spurious trailing ors
                sys.stdout.write(ors)


if __name__ == "__main__":
    main()
