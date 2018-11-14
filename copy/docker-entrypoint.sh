#!/bin/sh
# Same settings as in Dockerfile:
REPOSITORY_ROOT='/repos'
REPOSITORY_DUMMY="$REPOSITORY_ROOT/If_you_see_this_then_the_host_volume_was_not_mounted"


# Abort if the host's volume was not mounted read-only.
if [ ! -d "$REPOSITORY_DUMMY" ]; then
	#RO=$(findmnt -no 'OPTIONS' "$REPOSITORY_ROOT" 2>&1 | tr , "\n" | grep -F ro);	# part of util-linux package
	RO=$(sed -En 's|^\S+\s+'"$REPOSITORY_ROOT"'\s+\S+\s+(\S+).*|\1|p' < /proc/mounts | tr , "\n" | grep -F ro)
	if [ -z "$RO" ]; then
		echo "$0: Aborted to protect you from your own bad habits because you didn't mount the volume $REPOSITORY_ROOT read-only using the :ro attribute" >&2
		exit 1
	fi
fi


# Default entrypoint (as defined by Dockerfile CMD):
if [ "$(echo $1 | cut -c1-6)" = 'cvsweb' ]; then
	CVSWEB_ROOT='/var/www/cvsweb'

	# Set gid of cvsweb so that it can read the host's volume
	if [ ! -d "$REPOSITORY_DUMMY" ]; then
		if [ -z "$CVSWEB_GID" ]; then
			# CVSWEB_GID not given and volume was mounted, so read gid from mounted volume.
			CVSWEB_GID=$(stat -c%g "$REPOSITORY_ROOT")
			echo "$0: Host's volume has gid $CVSWEB_GID" >&2
		elif ! echo "$CVSWEB_GID" | grep -qE '^[0-9]{1,9}$'; then
			echo "$0: Bad gid syntax in CVSWEB_GID environment variable ($CVSWEB_GID)" >&2
			exit 1
		fi
		CVSWEB_GROUP=www-data
		CURRENT_GID=$(getent group "$CVSWEB_GROUP" | cut -d: -f3)
		if [ "$CVSWEB_GID" = "$CURRENT_GID" ]; then
			echo "$0: cvsweb is already configured to use the gid $CVSWEB_GID($CVSWEB_GROUP)"
		else
			GROUP=$(getent group "$CVSWEB_GID" | cut -d: -f1)
			if [ -z "$GROUP" ]; then	# no existing group has the requested gid
				if [ "$(id -u)" = '0' ]; then
					groupmod -g "$CVSWEB_GID" "$CVSWEB_GROUP"
				else
					echo "$0: You need to run this script as root in order to add a new group" >&2
					exit 1
				fi
			else
				echo "$0: Can't use the given CVSWEB_GID value ($CVSWEB_GID) as it already belongs to the group $GROUP" >&2
				exit 1
			fi
			echo "$0: cvsweb gid set to $CVSWEB_GID($CVSWEB_GROUP)"
		fi
	fi

	# Set cvsweb's debug mode (default is off).
	CVSWEB_DEBUG_FILE='/etc/cvsweb/conf.d/debug.conf'
	if [ -z "$CVSWEB_DEBUG" ] || [ "$CVSWEB_DEBUG" = '0' ]; then
		if [ -f "$CVSWEB_DEBUG_FILE" ]; then
			rm "$CVSWEB_DEBUG_FILE"
		fi
	else
		if [ ! -f "$CVSWEB_DEBUG_FILE" ]; then
			printf "use strict;\nour \$DEBUG = 1;\n" > "$CVSWEB_DEBUG_FILE"
		fi
	fi

	# Start nginx and cvsweb
	exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
else
	# All other entry points. Typically /bin/bash
	exec "$@"
fi
