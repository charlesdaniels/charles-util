*************************************
Documentation for ``desktop-spooler``
*************************************

.. contents::



This script is used to hook other scripts that need to run under various
conditions, and which I have not found better hooks for. This is highly
specific to my setup, and probably will be of minimal use to anyone else.

This script runs a loop every $DESKTOP_SPOOLER_INTERVAL. When this loop runs,
it polls lsusb to see if any of the USB device IDs specified in
~/.dspool/dock_devices.txt exist, using this information to populate
$DOCK_STATE. If $DOCK_STATE changes, the script restore-sanity is executed,
and the file $DOCK_SPOOLER_DIR/dock_status is updated.


License
=======


Copyright 2018, Charles A. Daniels
This software is distributed under the BSD 3-clause license. The full text
of this software's license may be retrieved from this URL:
https://github.com/charlesdaniels/dotfiles/blob/master/LICENSE






















