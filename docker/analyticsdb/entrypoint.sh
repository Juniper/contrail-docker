#!/usr/bin/env bash
set -x
source /common.sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/supervisord
SERVICE=database
NAME=supervisord_${SERVICE}
DESC=supervisor_${SERVICE}
ANSIBLE_INVENTORY=${ANSIBLE_INVENTORY:-"all-in-one"}

IPADDRESS=${IPADDRESS:-${primary_ip}}
CONFIG_IP=${CONFIG_IP:-$IPADDRESS}
API_SERVER_IP=${API_SERVER_IP:-${CONTRAIL_INTERNAL_VIP:-$CONFIG_IP}}
DATABASE_IP=${DATABASE_IP:-$IPADDRESS}

SERVICE_TENANT=${SERVICE_TENANT:-service}
KEYSTONE_AUTH_PROTOCOL=${KEYSTONE_AUTH_PROTOCOL:-http}
KEYSTONE_AUTH_PORT=${KEYSTONE_AUTH_PORT:-35357}
KEYSTONE_INSECURE=${KEYSTONE_INSECURE:-False}
KEYSTONE_ADMIN_USER=${OS_USERNAME:-admin}
KEYSTONE_ADMIN_PASSWORD=${OS_PASSWORD:-admin}
KEYSTONE_ADMIN_TENANT=${OS_TENANT_NAME:-admin}
KEYSTONE_ADMIN_TOKEN=${OS_TOKEN:-$ADMIN_TOKEN}
REGION=${REGION:-RegionOne}

test -x $DAEMON || exit 0

LOG=/var/log/supervisor_${SERVICE}
SOCKETFILE=$(awk '/^file=/ {print $1}' /etc/contrail/supervisord_${SERVICE}.conf | cut -f2 -d=)

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
    cd /contrail-ansible/playbooks/
    ansible-playbook -i inventory/$ANSIBLE_INVENTORY \
        -t provision,configure contrail_analyticsdb.yml
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

cd /contrail-ansible/playbooks/
ansible-playbook -i inventory/$ANSIBLE_INVENTORY -t service contrail_analyticsdb.yml

# Register contrail-database in config
retry /usr/share/contrail-utils/provision_database_node.py --api_server_ip $API_SERVER_IP \
    --host_name ${MYHOSTNAME} --host_ip ${DATABASE_IP} --oper add \
    --admin_user ${KEYSTONE_ADMIN_USER} --admin_password ${KEYSTONE_ADMIN_PASSWORD} \
     --admin_tenant_name ${KEYSTONE_ADMIN_TENANT}

wait "$child"
