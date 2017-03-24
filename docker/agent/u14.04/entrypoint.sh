#!/usr/bin/env bash
set -x
set -e
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/supervisord
SERVICE=vrouter
NAME=supervisord_${SERVICE}
DESC=supervisor_${SERVICE}
ANSIBLE_INVENTORY=${ANSIBLE_INVENTORY:-"all-in-one"}

test -x $DAEMON || exit 1

LOG=/var/log/supervisor_${SERVICE}
SOCKETFILE=$(awk '/^file=/ {print $1}' /etc/contrail/supervisord_${SERVICE}.conf | cut -f2 -d=)

# Include supervisor defaults if available
if [ -f /etc/default/supervisor_${SERVICE} ] ; then
	. /etc/default/supervisor_${SERVICE}
fi
DAEMON_OPTS="-n -c /etc/contrail/supervisord_${SERVICE}.conf $DAEMON_OPTS"

function cleanup() {
    supervisorctl -s unix://${SOCKETFILE} stop all
    supervisorctl -s unix://${SOCKETFILE} shutdown
    rm -f $SOCKETFILE
}

trap cleanup SIGHUP SIGINT SIGTERM

ulimit -s unlimited
ulimit -c unlimited
ulimit -d unlimited
ulimit -v unlimited
ulimit -n 4096
contrailctl config sync -c agent -F -v -t configure
$DAEMON $DAEMON_OPTS 2>&1 | tee -a $LOG &
child=$!

# run contrailctl to run code to make sure services are running
contrailctl config sync -c agent -F -v -t service,provision
wait "$child"
