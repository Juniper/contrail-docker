#!/bin/bash

# Copyright (c) 2017 Juniper Networks, Inc.
# All rights reserved

target=${1:-all}
[[ -z $1 ]] && echo "WARN: no target given, defaulting to \"all\""

function find_tgz() {
    tgz=$1
    if [[ -f $BUILD_WORKAREA/$tgz ]]; then
	echo $BUILD_WORKAREA/$tgz
    elif [[ -f $BUILD_WORKAREA/$BUILD_SANDBOX/build/artifacts/$tgz ]]; then
	echo $BUILD_WORKAREA/$BUILD_SANDBOX/build/artifacts/$tgz
    elif [[ -f $BUILD_WORKAREA/$BUILD_SANDBOX/build/artifacts_extra/$tgz ]]; then
	echo $BUILD_WORKAREA/$BUILD_SANDBOX/build/artifacts_extra/$tgz
    fi
}

# These settings work for JB env and CI build env.
# TODO: extend them to handle dev env
# Longer term: migrate these into docker/Makefile
#
BUILD_ID=${BUILD_ID:-$ZUUL_CHANGE.$ZUUL_PATCHSET}
BUILD_WORKAREA=${BUILD_WORKAREA:-$WORKSPACE}
BUILD_SANDBOX=${BUILD_SANDBOX:-repo}
BUILD_SKU=${BUILD_SKU:-$OPENSTACK_RELEASE}
BUILD_PLATFORM=${BUILD_PLATFORM:-${OS_TYPE2}}

case $BUILD_PLATFORM in
    ubuntu-14-04|ubuntu1404)		    OS=ubuntu14.04 ;;
    ubuntu-16-04|ubuntu1604)		    OS=ubuntu16.04 ;;
    centos71|centoslinux71)		    OS=centos7 ;;
    redhat70|redhatenterpriselinuxserver70) OS=redhat7 ;;
    *)	echo "WARN: Do not know how to build app containers for BUILD_PLATFORM=\"$BUILD_PLATFORM\", skipping"
	exit 0
	;;
esac

# TODO: this should use ssh key w/ no passphrase
export SSHPASS=c0ntrail123

build_version="$(cat $BUILD_WORKAREA/$BUILD_SANDBOX/controller/src/base/version.info)-$BUILD_ID"

container_build_workspace=$BUILD_WORKAREA/$BUILD_SANDBOX/tools/docker
container_save_location=$BUILD_WORKAREA/$BUILD_SANDBOX/build/artifacts
docker_ip=$(ip addr show docker0 | grep 'inet ' | sed -e 's/.*inet \([^ /]*\).*/\1/' 2>/dev/null)

tar_url=ssh://$docker_ip/$(find_tgz contrail-install-packages_$build_version-$BUILD_SKU.tgz)
if [[ $OS = redhat7 ]]; then
    tar_url="$tar_url,ssh://$docker_ip/$(find_tgz contrail-thirdparty-packages_$build_version-$BUILD_SKU.tgz)"
fi
ansible_tgz=$(find_tgz contrail-ansible-internal-$build_version.tar.gz)

log_location=$BUILD_WORKAREA/$BUILD_SANDBOX/build-info
log=$log_location/container-apps-${target}.log
mkdir -p $log_location

MAKE_ARGS="CONTRAIL_INSTALL_PACKAGE_TAR_URL=$tar_url"
MAKE_ARGS="$MAKE_ARGS CONTRAIL_VERSION=$build_version"
MAKE_ARGS="$MAKE_ARGS CONTRAIL_ANSIBLE_ARTIFACT=$ansible_tgz"
MAKE_ARGS="$MAKE_ARGS CONTAINER_REGISTRY=${REGISTRY_SERVER:-10.84.34.155}:5000"
MAKE_ARGS="$MAKE_ARGS CONTAINER_SAVE_LOCATION=$container_save_location"

cd $container_build_workspace
set -o pipefail			# So that we exit with make's exit status, not tee's
make OS=$OS $MAKE_ARGS $target 2>&1 | tee -a $log
exit $?
