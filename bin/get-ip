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
Get the IP address of the primary NIC on the system. This works by opening a
socket connection and immediately closing it, then inspecting the local side of
the socket to see which IP address is the origin of the connection. This makes
a nice way to determine what IP the running machine can be reached at even when
multiple NICs are present, or a given NIC has several IP addresses. Note that
this script is guaranteed to return an IP that the system it is run at is
resolvable at, but not necessarily the *only* such IP. As a convenience
feature, this script also supports retrieving the current system's WAN IP using
ident.me and/or icanhazip.com.
"""

import socket
import ipaddress
import argparse
import urllib.request
import sys

def get_lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except:
        IP = '127.0.0.1'
    finally:
        s.close()

    IP = ipaddress.ip_address(IP)

    return IP

def get_wan_ip():
    wan_ip = "127.0.0.1"
    try:
        wan_ip = urllib.request.urlopen('https://ident.me').read().decode('utf8')
    except Exception as e:
        # this may throw - the caller should catch it
        wan_ip = urllib.request.urlopen('https://icanhazip.com').read().decode('utf8')

    return ipaddress.ip_address(wan_ip)

def main():

    parser = argparse.ArgumentParser(description=descr)

    parser.add_argument('--version', action='version', version=version)

    parser.add_argument("--wan", "-w", action="store_true", default=False,
            help="Fetch the WAN IP of the current system from ident.me, and" +
            "then from icanhazip.com if that fails.")

    parser.add_argument("--int", "-n", action="store_true", default=False,
            help="Display the output IP as an integer, rather than a string.")

    args = parser.parse_args()

    ip = "127.0.0.1"

    if args.wan:
        try:
            ip = get_wan_ip()
        except Exception as e:
            sys.stderr.write("ERROR: failed to get WAN IP: {}\n".format(e))
            sys.exit(1)
    else:
        ip = get_lan_ip()

    if args.int:
        sys.stdout.write(int(ip))
    else:
        sys.stdout.write(str(ip))

if __name__ == "__main__":
    main()
