#!/bin/bash

## Variables passed in from AZ DevOps
# $PACKER_VERSION
export PACKER_ZIPFILE="packer_"$PACKER_VERSION"_linux_amd64.zip"
export PACKER_URL="https://releases.hashicorp.com/packer/"$PACKER_VERSION"/"$PACKER_ZIPFILE

apt update
apt install -y unzip

curl -o $PWD/$PACKER_ZIPFILE $PACKER_URL
unzip $PACKER_ZIPFILE