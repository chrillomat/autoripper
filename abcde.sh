#!/bin/bash

. autoripper.conf

$MYDIR/xbmc-notify.py "Started ripping $7"
OUTPUTDIR=$1 WAVOUTPUTDIR=${1}/tmp/ OUTPUTTYPE=$2 $3 -c $4/abcde.conf ${8}
chown -R ${5}: "${6}/${7}"
$MYDIR/updatexbmc.py
$MYDIR/xbmc-notify.py "Finished ripping $7"
