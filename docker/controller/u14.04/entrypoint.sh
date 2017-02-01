#!/usr/bin/env bash
set -x
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/supervisord
ANSIBLE_INVENTORY=${ANSIBLE_INVENTORY:-"all-in-one"}

test -x $DAEMON || exit 1

LOG=/var/log/supervisord.log

# Include supervisor defaults if available
if [ -f /etc/default/supervisord ] ; then
	. /etc/default/supervisord
fi
DAEMON_OPTS="-n -c /etc/contrail/supervisord.conf $DAEMON_OPTS"

function cleanup() {
    supervisorctl -c /etc/contrail/supervisord.conf stop all
    supervisorctl -c /etc/contrail/supervisord.conf shutdown
    rm -f $SOCKETFILE
}

trap cleanup SIGHUP SIGINT SIGTERM

ulimit -s unlimited
ulimit -c unlimited
ulimit -d unlimited
ulimit -v unlimited
ulimit -n 4096
# configure services and start them using ansible code within contrail-ansible
contrailctl config sync -c controller -F -t configure

$DAEMON $DAEMON_OPTS 2>&1 | tee -a $LOG &
child=$!
sleep 5

# run contrailctl to run code to make sure services are running
contrailctl config sync -c controller -F -t service,provision

wait "$child"
