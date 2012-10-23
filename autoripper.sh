#!/bin/bash -x


# autoripper wrapper script to check if audio cd is new (as in: yet unripped)
# and run abcde accordingly


## CONFIG
CDROM="/dev/sr0"
DESTINATION="${HOME}/Music/"
MYDIR="/usr/local/autoripper/"
DISCIDTOOL="/usr/bin/cd-discid"
ABCDE="/usr/bin/abcde"

AUDIOFORMAT="flac"

CDDBTOOL="/usr/bin/cddb-tool"
CDDBURL='http://freedb.freedb.org:80/~cddb/cddb.cgi'
CDDBPROTO=6


## STOP CONFIG

# this is serious stuff - avoid touching it unless you know what you are doing

# debug
#env | tee /var/log/autoripper-env.log

# debug end


# global variables

	PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:${MYDIR}

	# "selected" array of cherrypicked tracks
#	declare -a selected

# stop global variables



# is cddb info valid and has cd info
#function check_cddb_info {
#	cddbinfocheck=0
#}


# eject cd
function do_eject {
	eject -r $CDROM
}


# check which audio cd this is and how many tracks it has
function get_cddb_info {

	DISCID="$( ${DISCIDTOOL} $CDROM )"
 	CDDBRESPONSE="$( ${CDDBTOOL} query ${CDDBURL} ${CDDBPROTO} ${USER} ${HOSTNAME} ${DISCID} | tail -n+2 | head -n 1 )"

	if [ $? == 0 ]
	then
		ARTISTALBUM="$(echo ${CDDBRESPONSE} | cut -d ' ' -f 3- | sed 's/\//-/g')"
		TRACKS="$( echo $DISCID | cut -d ' ' -f 2 )"
	else
		do_eject
	fi

}

# compare local files and cddb info
function check_local {
	# is there a directory for this artist/album combination?
	echo "${DESTINATION}/${ARTISTALBUM}"

	if [ -d "${DESTINATION}/${ARTISTALBUM}" ] # album directory exists
	then
		# get number of audio-files in this dir
		CNT=$(find "${DESTINATION}/${ARTISTALBUM}" -type f -name '*.flac' | wc -l)

		if [ $CNT < $TRACKS ] # files in dir is lower than tracks on disc
		then
			# => return incomplete
			LOCALCHECK="incomplete"
		else
			# => return complete
			LOCALCHECK="complete"
		fi
	else # new album
		# => return newalbum
		LOCALCHECK="newalbum"
	fi
}


# select tracks according to check_local()
function select_tracks {
	for i in `seq -w 1 $TRACKS` # check if each number ...
	do
		if ( ! -f "${DESTINATION}/${ARTISTALBUM}/${i}\ *" ) # ... is there and if not ...
		then
			selected+=( "${i}" ) # ... add to list of selected tracks
		fi
	done
}


# do the actual ripping
function do_ripping {
	$ABCDE -c ${MYDIR}/abcde.conf -o $AUDIOFORMAT "${selected[*]}" &
}





# MAIN
