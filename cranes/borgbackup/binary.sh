#!/bin/bash

set -eo pipefail

# we operate in the salave mount point
cd /salvage/

export BORG_ARGS="${BORG_ARGS:=--lock-wait 3600}"
export CREATE_ARGS="${CREATE_ARGS:=}"
export PRUNE_ARGS="${PRUNE_ARGS:=}"

function assertIsSet() {
	if [ -z "${!1}" ]; then
		echo "Environment variable '$1' is required but empty."
		exit 1
	fi
}

# salvage crane interface
assertIsSet "SALVAGE_MACHINE_NAME"
assertIsSet "SALVAGE_CRANE_NAME"
assertIsSet "SALVAGE_VOLUME_NAME"

export BORG_HOST_ID="${SALVAGE_MACHINE_NAME}-${SALVAGE_CRANE_NAME}-${SALVAGE_VOLUME_NAME}"

# user config
assertIsSet "ENCRYPTION"
assertIsSet "REPO_BASE_LOCATION"
assertIsSet "SINGLE_REPO"
assertIsSet "DO_COMPACT"

# in single repo mode, one repo is used for all volumes
case "$SINGLE_REPO" in
	true|1|yes|y|on|enable)
		# single repo
		export BORG_BASE_DIR="/borg/data/single_repo/"
		export BORG_REPO="$REPO_BASE_LOCATION"
		;;
	false|0|no|n|off|disable)
		# multi repo, use volume name as directory
		export BORG_BASE_DIR="/borg/data/multi_repo/$SALVAGE_VOLUME_NAME"
		export BORG_REPO="$REPO_BASE_LOCATION/$SALVAGE_VOLUME_NAME"
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
if ! borg $BORG_ARGS init -e "$ENCRYPTION" &> /tmp/borg-init.log; then
	# init failed, but might be because repo already existed
	
	if ! grep -q "A repository already exists at" /tmp/borg-init.log; then
		cat /tmp/borg-init.log
		echo "Could not check for existing repository"
		exit 1
	fi
fi

# create a new archive
echo "calling create"
borg $BORG_ARGS create \
	$CREATE_ARGS \
	--list \
	::"$VOLUME_PREFIX-$(date +%Y-%m-%d_%H-%M-%S)" \
	.

if [ -n "$PRUNE_ARGS" ]; then

	echo "calling prune"
	borg $BORG_ARGS prune \
		$PRUNE_ARGS \
		--list \
		--show-rc \
		--glob-archives "$VOLUME_PREFIX-*"

	case "$DO_COMPACT" in
		true|1|yes|y|on|enable)
		echo "calling compact"
		borg $BORG_ARGS compact \
			--show-rc
		;;
	esac

fi
