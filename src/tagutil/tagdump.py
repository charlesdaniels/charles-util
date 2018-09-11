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

import argparse
import taglib
import yaml
import sys

parser = argparse.ArgumentParser(description="Dump tag information from " +
                                 "pytaglib for the specified (files). Data " +
                                 "is dumped in YAML format. Note that " +
                                 "if stdin is not a tty, each line of input" +
                                 " on it will be treated as a file to dump " +
                                 "tags for. This is useful for pipes.")

parser.add_argument("files", nargs="*", help="List of files to dump tags for",
                    default=[])
parser.add_argument("--input", "-i", default=None, help="A file to read " +
                    "where each line is a file to dump tags for.")
parser.add_argument("--tag_filter", "-t", default=None, help="Only tags" +
                    " listed here are sent to output. If unspecified, all" +
                    " tags are shown.", nargs="*")

parser.add_argument('--version', action='version', version=version)

args = parser.parse_args()

file_list = args.files
if args.input is not None:
    with open(args.input, 'r') as f:
        for line in f:
            file_list.append(line.strip())

if not sys.stdin.isatty():
    for line in sys.stdin:
        file_list.append(line.strip())

data_list = []
for f in file_list:
    song = None
    try:
        song = taglib.File(f)
    except OSError:
        continue
    data = song.tags
    for key in data:
        if len(data[key]) is 1:
            data[key] = data[key][0]
    drop_keys = []
    if args.tag_filter is not None:
        drop_keys = [key for key in data if key not in args.tag_filter]
    for key in drop_keys:
        data.pop(key)
    data_list.append(song.tags)

print(yaml.dump(data_list, default_flow_style=False))
