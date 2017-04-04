#!/usr/bin/env bash
set -x
set -e
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/supervisord
CONFIG=/etc/contrail/contrail-kubernetes.conf
SERVICE=kubernetes
ANSIBLE_INVENTORY=${ANSIBLE_INVENTORY:-"all-in-one"}

test -x $DAEMON || exit 0

DAEMON_OPTS="-n -c /etc/contrail/supervisord_${SERVICE}.conf $DAEMON_OPTS"
ulimit -s unlimited
ulimit -c unlimited
ulimit -d unlimited
ulimit -v unlimited
ulimit -n 4096
contrailctl config sync -c kubemanager -F -v -t configure
$DAEMON $DAEMON_OPTS
contrailctl config sync -c kubemanager -F -v -t service,provision
