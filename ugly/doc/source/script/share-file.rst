********************************
Documentation for ``share-file``
********************************

.. contents::



Script to share files using the Fastmail (or other FTP-based) file storage
system.


Description
===========


The use-case for this script is to fill the same use case as publicly-visible
Dropbox links, using Fastmail's FTP upload and file storage features. It
could probably be used with other sides that support FTP upload and HTTP
download also.

This script is configured by ~/.config/share-file/share-file.cfg, which
should be a source-able sh script with the following variables:

* ``SHARE_FILE_FTP_HOST`` - FTP host, for FastMail this will be
``ftp.fastmail.com``

* ``SHARE_FILE_FTP_PATH`` - path of root dir on the FTP server to upload to.
For FastMail, this should be ``/username.fastmail.com/files/``

* ``SHARE_FILE_HTTP_PATH`` - left-side of the URL, which when concatenated
with the file uploaded will be a publicly resolvable URL to the file.

Additionally, this script requires two tokens to be added to the
``get-token`` database:

* ``share-file-username`` FTP username to use

* ``share-file-password`` FTP password to use

On the Fastmail side, you will need to create a new folder, then create a
"files only" site. The folder you choose to populate it from will wind up
being ``foldername`` in ``SHARE_FILE_FTP_PATH``, and the website URL will be
``SHARE_FILE_HTTP_PATH``. The token ``share-file-username`` will be your
primary Fastmail email address, and ``share-file-password`` should be an
apps-password with only FTP access permissions.

For additional security, the file will be placed in a folder whose name is a
(shortened) random UUID, so if you upload ``foo.txt``, it will wind up in
``example.com/sharedfolder/some-uuid/foo.txt``. Assuming you also have
directory browsing disabled, this will prevent an attacker without a file's
full URL from guessing it via dictionary attack.

This script will also create a file, at the same URL, but with .meta appended
to the file name. This metadata file include the file name, the hostname and
username which uploaded, the time of the upload, and the shasum of the file.


Syntax
======

::


    $1 . . . Path to file to share (/dev/stdin for standard in)

    $2 . . . (optional) name to use on the remote end

    URL of the uploaded file will be printed to standard out
















