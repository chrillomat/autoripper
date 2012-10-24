#!/bin/bash

OUTPUTDIR=$ARG1 WAVOUTPUTDIR=${ARG1}/tmp/ OUTPUTTYPE=$ARG2 $ARG3 -c $ARG4/abcde.conf "${selected[*]}"
chown -R ${ARG5}: ${ARG6}/${ARG7}
