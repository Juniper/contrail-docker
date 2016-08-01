#!/usr/bin/env bash

source /env.sh

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/supervisord
SERVICE=control
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

# Get config api servers from discovery
api_servers=$(get_service_connect_details http://${DISCOVERY_SERVER}:${DISCOVERY_PORT}/services.json ApiServer)
first_api_server=$(echo $api_servers | awk '{print $1}')

api_server_ip=${first_api_server%:*}
api_server_port=${first_api_server#*:}
# Wait for config api
wait_for_url http://$first_api_server

# Add ASN to global system config
retry /usr/share/contrail-utils/provision_control.py --api_server_ip ${api_server_ip} \
    --api_server_port ${api_server_port} --router_asn ${ROUTER_ASN}  --admin_user ${KEYSTONE_ADMIN_USER} \
    --admin_password ${KEYSTONE_ADMIN_PASSWORD} --admin_tenant_name ${KEYSTONE_ADMIN_TENANT}

# Add the node as a BGP speaker
if [[ $BGP_MD5 ]]; then
    md5_param=" --md5 $BGP_MD5 "
fi

retry /usr/share/contrail-utils/provision_control.py --api_server_ip ${api_server_ip} \
    --api_server_port ${api_server_port} --router_asn ${ROUTER_ASN}  --admin_user ${KEYSTONE_ADMIN_USER} \
    --admin_password ${KEYSTONE_ADMIN_PASSWORD} --admin_tenant_name ${KEYSTONE_ADMIN_TENANT} ${md5_param} \
    --host_name $HOSTNAME --host_ip ${CONTROL_IP} --oper add

# Add external routers if any
# EXTERNAL_ROUTERS_LIST is a space delimited list of routers in form of routername:ipaddress
for ext_router in  $EXTERNAL_ROUTERS_LIST; do
    # ext_router will be in the form of <hostname>:<ipaddress>
    ext_router_name=${ext_router%:*}
    ext_router_ip=${ext_router#*:}
    retry /usr/share/contrail-utils/provision_mx.py --api_server_ip ${api_server_ip} \
        --api_server_port ${api_server_port} --router_name ${ext_router_name} \
        --router_ip ${ext_router_ip} --router_asn $ROUTER_ASN --admin_user ${KEYSTONE_ADMIN_USER} \
        --admin_password ${KEYSTONE_ADMIN_PASSWORD} --admin_tenant_name ${KEYSTONE_ADMIN_TENANT}
done

wait "$child"
