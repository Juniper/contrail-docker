#!/usr/bin/env bash
set -x
set -e
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
test -x $DAEMON || exit 0

# configure services and start them using ansible code within contrail-ansible
contrailctl config sync -c lb -F -v

## Setup haproxy
if [ -f /etc/default/haproxy ] ; then
	. /etc/default/haproxy
fi

mkdir -p /var/run/haproxy /var/log/haproxy
chown -R haproxy.haproxy /var/run/haproxy /var/log/haproxy

## END Setup haproxy

DAEMON=/usr/sbin/haproxy
DAEMON_OPTS="-f /etc/haproxy/haproxy.cfg -db"
LOG=/var/log/haproxy/haproxy-stdout.log

$DAEMON $DAEMON_OPTS 2>&1 | tee -a $LOG &
child=$!
wait "$child"
