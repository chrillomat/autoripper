#!/bin/bash

. autoripper.conf # get config

if [ -f autoripper.conf.local ]
then
	. autoripper.conf.local
fi

$MYDIR/xbmc-notify.py "Started ripping" # xbmc notification of rip start

$1 -c $2/abcde.conf -d $3 ${4} # do the actual ripping
ERR=$?

if [ $ERR -eq 0 ]
then
    #$MYDIR/updatexbmc.py # update the audio library in xbmc

    $MYDIR/xbmc-notify.py "Finished ripping" # xbmc notification of rip end
else
    echo "ERR: process abcde ended with error $ERR"
    $MYDIR/xbmc-notify.py "CD ripping error" # xbmc notification of rip error
    
fi
