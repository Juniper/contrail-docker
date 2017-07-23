#!/usr/bin/env bash
set -x
set -e
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
ANSIBLE_INVENTORY=${ANSIBLE_INVENTORY:-"all-in-one"}
trap cleanup SIGHUP SIGINT SIGTERM

ulimit -s unlimited
ulimit -c unlimited
ulimit -d unlimited
ulimit -v unlimited
ulimit -n 4096
contrailctl config sync -c kubernetesagent -F -v -t configure
