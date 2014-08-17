#!/bin/bash

# autoripper wrapper script to check if audio cd is new (as in: yet unripped)
# and run abcde accordingly

# CONFIG is in autoripper.conf
# TODO: use as much as possible from abcde.conf

SELF=$0
CDROM=/dev/$1 # TODO: check if this argument is supplied - if not -> do_eject
DIRNAME=$(dirname $SELF)

. $DIRNAME/autoripper.conf

if [ -f $DIRNAME/autoripper.conf.local ]
then
	. $DIRNAME/autoripper.conf.local
fi

# global variables

	PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:${MYDIR}

	# "selected" array of cherrypicked tracks
	declare -a selected
	# "available" array of all tracks on disk
	declare -a available

# stop global variables

# deal with errors
function do_eject {
#	eject $CDROM
    echo "process ended."
}


# check which audio cd this is and how many tracks it has
function get_cddb_info {
        echo "Getting CDDB infos..."
	CDDBTEMP=/tmp/.cddb
	$ABCDE -a cddb -N -d $CDROM > $CDDBTEMP
 	ERR=$?
	# TODO: for parsing cddb file we can also use acde function "do_cddbparse"

	if [ $ERR -eq 0 ]
	then
	        TMPDIR=$( tail -n1 /tmp/.cddb | cut -d ' '  -f 4 )
		TMPDIR=${TMPDIR%?}
		RETCODE=$( head -n1 $TMPDIR/cddbquery | cut -d ' '  -f 1 )

		case $RETCODE in
			200|210) # one or more entry
				ALBUMARTIST=$( grep DTITLE $TMPDIR/cddbread.1 | cut -d '=' -f 2 )
				# build list of tracks for later use (see check_local and select_tracks)
				TRACKS=$(expr $(cat $TMPDIR/cddbread.1 | grep TTITLE | tail -n1 | cut -d '=' -f 1 | cut --complement -b 1-6) + 1)
				for i in $(seq 0 $(expr $TRACKS - 1)) # check if each number ...
				do
				    available+=( "$( grep TTITLE${i}= $TMPDIR/cddbread.1 | cut -d = -f 2 )" ) # ... add to list of available tracks
				done
				;;
			202) # no entry
				do_eject
				echo "No CDDB entry for this disc"
				rm $CDDBTEMP
				exit 0
				;;
			*) # all other stuff
				do_eject
				echo "ERR: ${CDDBTOOL} exits with code $RETCODE"
				cat $CDDBTEMP
				rm $CDDBTEMP
				exit 0
				;;
		esac
	else
		do_eject
		echo "ERR: abcde exits with error $ERR"
	fi

	rm $CDDBTEMP

}

# compare local files and cddb info
function check_local {
	# TODO: for parsing cddb file we can also use acde function "do_cddbparse"
        echo "Checking for existing files on disk..."
        ARTIST=$( echo $ALBUMARTIST | cut -d '/' -f 1 )
	ARTIST=${ARTIST%?}
	ALBUM=$( echo $ALBUMARTIST | cut -d '/' -f 2 )
	ALBUM=${ALBUM#?}
	# is there a directory for this artist/album combination?
	# TODO: use abcde.conf / OUTPUTFORMAT
	DESTDIR="${DESTINATION}/${ARTIST}/${ALBUM}"
	echo $DESTDIR

	if [ -d "$DESTDIR" ] # album directory exists
	then
	        # leave it up to select_track which or if any tracks need to be ripped
		LOCALCHECK="incomplete"
	else # new album
		# => return newalbum
		LOCALCHECK="newalbum"
	fi
}


# select tracks according to check_local()
function select_tracks {
        echo "Existing files found - only selecting non-existing ones..."
	for i in $(seq 0 $(expr $TRACKS - 1)) # check if each number ...
	do
	        # check for each file vs. track name
	        # TODO: use abcde.conf / OUTPUTFORMAT
		if [ $(find "$DESTDIR" -type f -name "*${available[i]}.${AUDIOFORMAT}" | wc -l) -eq 0 ] # ... is not there and if so ...
		then
			selected+=( "$(expr $i + 1)" ) # ... add to list of selected tracks
		fi
	done
	echo "Number of tracks selected: ${#selected[@]}"
}


# do the actual ripping
function do_ripping {
        echo "Now starting ripping process..."
	${MYDIR}/abcde.sh "${ABCDE}" "${MYDIR}" "${CDROM}" "${selected[*]}"
	echo "Finished ripping."
}

### MAIN ###
get_cddb_info

check_local

case ${LOCALCHECK} in
	"incomplete")
		select_tracks
		if ( [ ${#selected[@]} -eq 0 ] )
		then
		    do_eject
		else
		    do_ripping
		fi
		;;
	"complete")
		do_eject
		;;
	"newalbum")
		do_ripping
		;;
	*)
		do_eject
		;;
esac
