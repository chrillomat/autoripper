# autoripper wrapper script to check if audio cd is new (as in: yet unripped)
# and run abcde accordingly

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

env | tee /var/log/autoripper-env.log

# check which audio cd this is and how many tracks it has
function check_cddb {
}


# see if audio cd was ripped and is complete
function check_local {
}


# do the actual ripping
function do_ripping {
}
