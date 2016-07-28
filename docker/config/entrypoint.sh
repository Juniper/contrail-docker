#!/bin/bash -x
source /env.sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/supervisord
SERVICE=config
NAME=supervisord_${SERVICE}
DESC=supervisor_${SERVICE}

test -x $DAEMON || exit 0

LOG=/var/log/supervisor_${SERVICE}
SOCKETFILE=/tmp/supervisord_${SERVICE}.sock

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
    bash -x /configure.sh
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

# Register config node in config db
wait_for_url http://${API_SERVER_IP}:${API_SERVER_PORT}
/usr/share/contrail-utils/provision_config_node.py --api_server_ip $API_SERVER_IP --host_name $HOSTNAME \
    --host_ip $API_SERVER_IP --oper add  --admin_user ${KEYSTONE_ADMIN_USER} \
    --admin_password ${KEYSTONE_ADMIN_PASSWORD} --admin_tenant_name ${KEYSTONE_ADMIN_TENANT}

wait "$child"
