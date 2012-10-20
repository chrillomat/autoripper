#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin


# autoripper wrapper script to check if audio cd is new (as in: yet unripped)
# and run abcde accordingly


## CONFIG
CDROM="/dev/sr0"
DESTINATION="$HOME/Music/"

DISCIDTOOL="/usr/bin/cd-discid"
CDDBTOOL="/usr/bin/cddb-tool"
CDDBURL="http://freedb.freedb.org:80/~cddb/cddb.cgi"
CDDBPROTO=6


## STOP CONFIG

# this is serious stuff - avoid touching it unless you know what you are doing

# debug
env | tee /var/log/autoripper-env.log

# debug end


# global variables

	# "selected" array of cherrypicked tracks
	declare -a selected

# stop global variables

# check which audio cd this is and how many tracks it has
function get_cddb_info {

	## ===>> /usr/bin/cddb-tool query "http://freedb.freedb.org:80/~cddb/cddb.cgi" 6 $USER $HOSTNAME `/usr/bin/cd-discid /dev/sr0`
	# 210 Found exact matches, list follows (until terminating `.')
	# data d30be90f Gorillaz / Demon Days
	# misc d30be90f Gorillaz / Demon Days
	# rock d30be90f Gorillaz / Demon Days
	# newage d30be90f Gorillaz / Demon Days
	# .

	DISCID="$(${DISCIDTOOL})"
	CDDBQUERY="query $CDDBURL $CDDBPROTO $USER $HOSTNAME ${DISCID}"
	CDDBRESPONSE="$($CDDBTOOL $CDDBQUERY)"

	ARTISTALBUM="$(echo ${CDDBRESPONSE} | head -n 2 | tail -n 1 | cut -d ' ' -f 3- | sed 's/\//\-/g')"
	TRACKS="echo $DISCID | cut -d ' ' -f 2)"

}


# is cddb info valid and has cd info?
function check_cddb_info {
}


# compare local files and cddb info
function check_local {
	# is there a directory for this artist/album combination?
	if ( -d "${DESTINATION}/${ARTISTALBUM}") { # album directory exists

		# get number of audio-files in this dir
		CNT=$()

		if ( $CNT < $TRACKS) { # files in dir is lower than tracks on disc
			# => return incomplete
		}
		else {
			# => return complete
		}
	}
	else { # new album
		# => return newalbum
	}
}


# select tracks according to check_local()
function select_tracks {
	for i in `seq -w 1 $TRACKS`
	do
		if ( ! -f "${DESTINATION}/${ARTISTALBUM}/${i}\ *" ) {
			selected+=( "${i}" )
		}
	done
}


# do the actual ripping
function do_ripping {
}


# eject cd
function do_eject {
}







# MAIN
