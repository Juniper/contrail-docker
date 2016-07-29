#!/usr/bin/env bash

set -x
set -a
set +e
source /env.sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/supervisord
SERVICE=database
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

function pre_start() {
    ulimit -s unlimited
    ulimit -c unlimited
    ulimit -d unlimited
    ulimit -v unlimited
    ulimit -n 4096
    python /configure.py
}

function cleanup() {
    supervisorctl -s unix://${SOCKETFILE} stop all
    supervisorctl -s unix://${SOCKETFILE} shutdown
    rm -f $SOCKETFILE
}

trap cleanup SIGHUP SIGINT SIGTERM
pre_start

setup_keystone_auth_config
setup_vnc_api_lib

$DAEMON $DAEMON_OPTS 2>&1 | tee -a $LOG &
child=$!
# Wait for config api
wait_for_url http://${CONFIG_API_IP}:${CONFIG_API_PORT}

# Register database in config
retry /usr/share/contrail-utils/provision_database_node.py --api_server_ip $CONFIG_API_IP \
    --host_name ${HOSTNAME} --host_ip ${DATABASE_IP} --oper add \
    --admin_user ${KEYSTONE_ADMIN_USER} --admin_password ${KEYSTONE_ADMIN_PASSWORD} \
     --admin_tenant_name ${KEYSTONE_ADMIN_TENANT}

wait "$child"
