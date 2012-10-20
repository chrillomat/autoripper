# zyanklee's autoripper

autoripper is a wrapper script which uses udev rules, some cddb request and abcde
to check on insertion if a specific audio cd is already ripped and if not rip it.
I designed the autoripper for ubuntu linux, it may work out of the box for any other
linux distro, but I did not test it.

If you change the script to fit in with another linux distro, please send me a diff
so I can merge it with the original code.


## contents

 * udev rules to start the wrapper script
 * wrapper script to check if cd is already ripped and to start abcde


## dependencies

 * abcde
 * udev
 * cd_discid

## license

see LICENSE.GPL
