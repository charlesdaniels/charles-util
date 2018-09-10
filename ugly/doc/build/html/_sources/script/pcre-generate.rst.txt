***********************************
Documentation for ``pcre-generate``
***********************************

.. contents::


This script reads in 1 or more PCRE compliant regular expressions, newline
delimited from standard in.

For each regex...

  * produce a random number from 0 to 100, if it is greater than n, skip
    processing this line. Thus, if n is 50, half of all inputs will be
    discarded. If n is 100, no inputs will be discarded.

  * for each remaining input line, generate a random string which is valid
    for the given regex, called v[k] for the kth input line

  * produce a string s with length l containing all elements in v
    concatenated, and separated by x characters of random padding such that
    m=(l+x)/l => x = l(m - 1) => l = x/(m-1). The resulting s is output to
    stdout.

Further, on standard error, the following is output:

  * for each element in v, the regex (input line) and the generated string,
    separated by a tab character, terminated with a newline

SYNTAX
$1 . . . . keep rate n (0 < n <= 100)

$2 . . . . padding factor m (0 < m < 2^32-1)

stdin  . . newline delimited, PCRE compliant regular expressions


License
=======


Copyright 2018, Charles A. Daniels
This software is distributed under the BSD 3-clause license. The full text
of this software's license may be retrieved from this URL:
https://github.com/charlesdaniels/dotfiles/blob/master/LICENSE







