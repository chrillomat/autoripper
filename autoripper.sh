#!/bin/bash -x


# autoripper wrapper script to check if audio cd is new (as in: yet unripped)
# and run abcde accordingly

# CONFIG is in autoripper.conf

SELF=$0
DIRNAME=$(dirname $SELF)

. $DIRNAME/autoripper.conf

if [ -f $DIRNAME/autoripper.conf.local ]
then
	. $DIRNAME/autoripper.conf.local
fi

# this is serious stuff - avoid touching it unless you know what you are doing

# debug
#env | tee /var/log/autoripper-env.log

# debug end


# global variables

	PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:${MYDIR}

	# "selected" array of cherrypicked tracks
	declare -a selected
	declare -a available

# stop global variables



# is cddb info valid and has cd info
#function check_cddb_info {
#	cddbinfocheck=0
#}


# eject cd
function do_eject {
#	eject $CDROM
	lockfile-remove --lock-name $LOCKFILE
}


# check which audio cd this is and how many tracks it has
function get_cddb_info {

        CDDBTEMP=/tmp/.cddb
	sudo -u $RECIPIENT $ABCDE -a cddb -N > $CDDBTEMP
 	ERR=$?

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
        ARTIST=$( echo $ALBUMARTIST | cut -d '/' -f 1 )
	ARTIST=${ARTIST%?}
	ALBUM=$( echo $ALBUMARTIST | cut -d '/' -f 2 )
	ALBUM=${ALBUM#?}
	# is there a directory for this artist/album combination?
	DESTDIR="${DESTINATION}/${ARTIST}/${ALBUM}"
	echo $DESTDIR

	# BAUSTELLE: even if number of files in directory matches number of tracks, we still need to compare filenames!
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
	for i in $(seq 0 $(expr $TRACKS - 1)) # check if each number ...
	do
	        # check for each file vs. track name
		if [ $(find "$DESTDIR" -type f -name "*${available[i]}.${AUDIOFORMAT}" | wc -l) -eq 0 ] # ... is not there and if so ...
		then
			selected+=( "$(expr $i + 1)" ) # ... add to list of selected tracks
		fi
	done
}


# do the actual ripping
function do_ripping {
	${MYDIR}/abcde.sh "${DESTINATION}" "${AUDIOFORMAT}" "${ABCDE}" "${MYDIR}" "${RECIPIENT}" "${DESTINATION}" "${ARTISTALBUM}" "${selected[*]}" &
}





# MAIN

MULTIPLIER=1 # generates from 0 - 9.99999
SLEEP=$( echo "scale=1; $RANDOM*$MULTIPLIER/32767" | bc )

sleep $SLEEP

if [ -f $LOCKFILE ]
then
	lockfile-check --use-pid --lock-name $LOCKFILE
	LOCKCHECK=$?

	LOCKPID=$(cat $LOCKFILE)

	# if cat $LOCKFILE still running?
	if ( [ $( ps -p $LOCKPID -o pid,comm --no-heading | grep -q 'autoripper' ; echo $? ) -eq 0 ] || [ $( ps auxwww | grep -v grep | grep -q 'abcde' ; echo $? ) -eq 0 ] )
	then
		exit 0 # not running twice, die!
	fi

	# anything from here should only happen if autoripper or abcde are not running atm

	lockfile-remove --lock-name $LOCKFILE # removing stale lockfile
fi

lockfile-create --use-pid --lock-name $LOCKFILE # creating lockfile

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

#lockfile-remove --lock-name $LOCKFILE # removing lockfile after ripping ends in abcde.sh
