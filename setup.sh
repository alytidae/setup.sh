#!/bin/bash
set -e

source config.sh

if [[ "$SETUP_START" != "true" ]]; then
  echo "You need to set \"SETUP_START=true\" in config.sh to setup.sh started execution"
  exit 1
fi

#source modules/install-packages-"$SETUP_DISTRO".sh
source modules/select-disk.sh
source modules/partition-crypt.sh
source modules/cryptsetup.sh
source modules/xchroot.sh

#source modeles/create-user.sh
