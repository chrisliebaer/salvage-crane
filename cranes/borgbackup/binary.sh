#!/bin/bash

set -eo pipefail


export BORG_ARGS="${BORG_ARGS:=--lock-wait 3600}"
export CREATE_ARGS="${CREATE_ARGS:=}"
export PRUNE_ARGS="${PRUNE_ARGS:=}"
export BORG="${BORG:=borg}"

function assertIsSet() {
	if [ -z "${!1}" ]; then
		echo "Environment variable '$1' is required but empty."
		exit 1
	fi
}

# testing flag defines alias that will replace borg with echo
if [ "$TESTING" == "true" ]; then
	echo "*** TESTING MODE ENABLED ***"
	echo "WARNING: TESTING mode enabled, all commands will be echoed instead of executed, NO BACKUP WILL BE DONE"
	echo "*** TESTING MODE ENABLED ***"
	BORG="echo"
else
	# we operate in the salave mount point
	cd /salvage/
fi

# salvage crane interface
assertIsSet "SALVAGE_MACHINE_NAME"
assertIsSet "SALVAGE_CRANE_NAME"
assertIsSet "SALVAGE_VOLUME_NAME"
assertIsSet "SALVAGE_TIDE_TIMESTAMP"

echo "borg crane '$SALVAGE_CRANE_NAME' on machine '$SALVAGE_MACHINE_NAME' starting backup of volume '$SALVAGE_VOLUME_NAME'"

export BORG_HOST_ID="${SALVAGE_MACHINE_NAME}-${SALVAGE_CRANE_NAME}-${SALVAGE_VOLUME_NAME}"

# user config
assertIsSet "ENCRYPTION"
assertIsSet "REPO_BASE_LOCATION"
assertIsSet "SINGLE_REPO"
assertIsSet "DO_COMPACT"

# user can pass repository location in two ways:
# 1. the repo location is static, and is used for all backups
# 2. a semicolon separated list of repo locations, which are rotated on a daily basis
#    the first repo is used for the first day, the second for the second day, etc.
#    the rotation is based on the number of days since the epoch, so it is not affected by the current date
#
# semicolons can also be trailing or come in pairs like this: ";;"
# in these cases, we just ignore the empty entries

# a semicolon somewhere in the string indicates a list of repo locations
if [[ "$REPO_BASE_LOCATION" == *";"* ]]; then
	echo "Detected multiple repository locations for rotation"
	
	# Split the string by semicolons and filter out empty entries
	IFS=';' read -ra REPO_LOCATIONS <<< "$REPO_BASE_LOCATION"
	VALID_REPOS=()
	
	for REPO in "${REPO_LOCATIONS[@]}"; do
		# Skip empty entries
		if [[ -n "$REPO" ]]; then
			VALID_REPOS+=("$REPO")
		fi
	done
	
	echo "Found ${#VALID_REPOS[@]} valid repositories after filtering empty entries"
	
	# Calculate days since epoch for rotation
	DAYS_SINCE_EPOCH=$(( SALVAGE_TIDE_TIMESTAMP / 86400 ))
	
	# If we have valid repos, select one based on rotation
	if [[ ${#VALID_REPOS[@]} -gt 0 ]]; then
		REPO_INDEX=$(( DAYS_SINCE_EPOCH % ${#VALID_REPOS[@]} ))
		SELECTED_REPO="${VALID_REPOS[$REPO_INDEX]}"
		echo "Using rotated repo: $SELECTED_REPO (index ${REPO_INDEX}, day ${DAYS_SINCE_EPOCH})"
	else
		echo "ERROR: No valid repositories found in rotation list"
		echo "input was: $REPO_BASE_LOCATION<END> (note: <END> is not part of the input)"
		exit 1
	fi
else
	# no semicolon, use the static repo location
	echo "Using static repo location: $REPO_BASE_LOCATION (no rotation)"
	SELECTED_REPO="$REPO_BASE_LOCATION"
fi


# in single repo mode, one repo is used for all volumes
case "$SINGLE_REPO" in
	true|1|yes|y|on|enable)
		# single repo
		export BORG_BASE_DIR="/borg/data/single_repo/"
		export BORG_REPO="$SELECTED_REPO"
		;;
	false|0|no|n|off|disable)
		# multi repo, use volume name as directory
		export BORG_BASE_DIR="/borg/data/multi_repo/$SALVAGE_VOLUME_NAME"
		export BORG_REPO="$SELECTED_REPO/$SALVAGE_VOLUME_NAME"
		;;
	*)
		echo "'SINGLE_REPO' contains invalid value '$SINGLE_REPO' (must be true/false)"
		exit 1
		;;
esac

# default would create slightly more annoying paths
export BORG_CACHE_DIR="$BORG_BASE_DIR/cache"
export BORG_CONFIG_DIR="$BORG_BASE_DIR/config"


# default is to use only the volume name as prefix, a common alternative is to use the machine name as well
VOLUME_PREFIX="v_$SALVAGE_VOLUME_NAME"
if [ -n "$CUSTOM_PREFIX" ]; then
	VOLUME_PREFIX=$(eval "echo $CUSTOM_PREFIX")
fi

# first time requires repo creation, borg has no built-in method for checking so we rely on unstable output
echo "calling init if repo does not already exist"
if ! "$BORG" --show-rc $BORG_ARGS init -e "$ENCRYPTION" &> /tmp/borg-init.log; then
	# init failed, but might be because repo already existed
	
	if ! grep -q "A repository already exists at" /tmp/borg-init.log; then
		cat /tmp/borg-init.log
		echo "Could not check for existing repository"
		exit 1
	fi
fi

# create a new archive
echo "calling create"
"$BORG" --show-rc $BORG_ARGS create \
	$CREATE_ARGS \
	--list \
	::"$VOLUME_PREFIX-$(date +%Y-%m-%d_%H-%M-%S)" \
	.

if [ -n "$PRUNE_ARGS" ]; then

	echo "calling prune"
	"$BORG" --show-rc $BORG_ARGS prune \
		$PRUNE_ARGS \
		--list \
		--glob-archives "$VOLUME_PREFIX-*"

	case "$DO_COMPACT" in
		true|1|yes|y|on|enable)
		echo "calling compact"
			"$BORG" --show-rc $BORG_ARGS compact
			;;
	esac

fi
