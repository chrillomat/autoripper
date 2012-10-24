#!/bin/bash

OUTPUTDIR=$1 WAVOUTPUTDIR=${1}/tmp/ OUTPUTTYPE=$2 $3 -c $4/abcde.conf ${8}
chown -R ${5}: "${6}/${7}"
