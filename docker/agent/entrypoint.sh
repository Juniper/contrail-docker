#!/usr/bin/env bash
set -x
source /env.sh

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/supervisord
SERVICE=vrouter
NAME=supervisord_${SERVICE}
DESC=supervisor_${SERVICE}

test -x $DAEMON || exit 0

LOG=/var/log/supervisor_${SERVICE}
SOCKETFILE=$(awk '/^file=/ {print $1}' /etc/contrail/supervisord_${SERVICE}.conf | cut -f2 -d=)

# Include supervisor defaults if available
if [ -f /etc/default/supervisor_${SERVICE} ] ; then
	. /etc/default/supervisor_${SERVICE}
fi
DAEMON_OPTS="-n -c /etc/contrail/supervisord_${SERVICE}.conf $DAEMON_OPTS"

set -e

function pre_start() {
    ulimit -s unlimited
    ulimit -c unlimited
    ulimit -d unlimited
    ulimit -v unlimited
    ulimit -n 4096
    bash /configure.sh
}

function cleanup() {
    supervisorctl -s unix://${SOCKETFILE} stop all
    supervisorctl -s unix://${SOCKETFILE} shutdown
    rm -f $SOCKETFILE
}

trap cleanup SIGHUP SIGINT SIGTERM

pre_start
$DAEMON $DAEMON_OPTS 2>&1 | tee -a $LOG &
child=$!

# Register vrouter-agent in config
retry /usr/share/contrail-utils/provision_vrouter.py  --api_server_ip $CONFIG_IP \
    --host_name ${MYHOSTNAME} --host_ip ${VIRTUAL_HOST_INTERFACE_IP} --oper add \
    --admin_user ${KEYSTONE_ADMIN_USER} --admin_password ${KEYSTONE_ADMIN_PASSWORD} \
     --admin_tenant_name ${KEYSTONE_ADMIN_TENANT}

wait "$child"
