#!/usr/bin/env bash

DESC="Cassandra"
NAME=cassandra
PIDFILE=/var/run/$NAME/$NAME.pid
CONFDIR=/etc/cassandra
WAIT_FOR_START=10
CASSANDRA_HOME=/usr/share/cassandra
FD_LIMIT=100000

[ -e /usr/share/cassandra/apache-cassandra.jar ] || exit 0
[ -e /etc/cassandra/cassandra.yaml ] || exit 0
[ -e /etc/cassandra/cassandra-env.sh ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Export JAVA_HOME, if set.
[ -n "$JAVA_HOME" ] && export JAVA_HOME

cassandra_home=`getent passwd cassandra | awk -F ':' '{ print $6; }'`
heap_dump_f="$cassandra_home/java_`date +%s`.hprof"
error_log_f="$cassandra_home/hs_err_`date +%s`.log"

start-stop-daemon -S -c cassandra -a /usr/sbin/cassandra -p "$PIDFILE" -- \
    -f -p "$PIDFILE" -H "$heap_dump_f" -E "$error_log_f"