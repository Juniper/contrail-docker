#!/usr/bin/env bash
set -x
set -e
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
SERVICE=contrail-vcenter-plugin
ANSIBLE_INVENTORY=${ANSIBLE_INVENTORY:-"all-in-one"}
ulimit -s unlimited
ulimit -c unlimited
ulimit -d unlimited
ulimit -v unlimited
ulimit -n 4096
contrailctl config sync -c vcenterplugin -F -v -t configure
child=$(pgrep -f juniper-contrail-vcenter.jar)
while [ -e /proc/$child ]; do sleep 100; done

