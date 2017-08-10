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

# Variables to cache arguments.
loop=0

# Parse arguments.
while getopts ":l" arg; do
    case $arg in
        l)
            loop=1
            ;;
        *)
            ;;
    esac
done

contrailctl config sync -c kubernetesagent -F -v -t configure

# If looping is requested, loop forever.
if [ $loop -eq "1" ]; then
    tail -f /dev/null
fi
