********************************
Documentation for ``git-backup``
********************************

.. contents::


Back up a git repository to a local file. The file produced will be a tarfile
containing the git repository as a git .bundle file, as well as an xz
compressed tarball of the current HEAD for the master branch of the repo. The
latter is included so the archive produced is still useful if it needs to be
unpacked on a system without git, or if the git bundle format is ever
depricated.


Syntax
======

::


    $1 . . . URL of repository to back up

    $2 . . . Path to backup file (.tar extension will be added automatically)


License
=======


Copyright 2018, Charles A. Daniels
This software is distributed under the BSD 3-clause license. The full text
of this software's license may be retrieved from this URL:
https://github.com/charlesdaniels/dotfiles/blob/master/LICENSE












