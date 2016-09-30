#!/bin/bash -x
source /env.sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/supervisord

test -x $DAEMON || exit 0

LOG=/var/log/supervisord.log
SOCKETFILE=/var/run/supervisor.sock

# Include supervisor defaults if available
if [ -f /etc/default/supervisord ] ; then
	. /etc/default/supervisord
fi
DAEMON_OPTS="-n -c /etc/contrail/supervisord.conf $DAEMON_OPTS"

function pre_start() {
    ulimit -s unlimited
    ulimit -c unlimited
    ulimit -d unlimited
    ulimit -v unlimited
    ulimit -n 4096
    chown -R cassandra.cassandra /var/lib/cassandra
    chown -R zookeeper.zookeeper /var/lib/zookeeper
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

sleep 5

cd /contrail-ansible/playbooks/
ansible-playbook -i inventory/$ANSIBLE_INVENTORY -t service contrail_controller.yml

# Register config node in config db
wait_for_url http://${API_SERVER_IP}:${API_SERVER_PORT}
retry /usr/share/contrail-utils/provision_config_node.py --api_server_ip $API_SERVER_IP --host_name $MYHOSTNAME \
    --host_ip $API_SERVER_IP --oper add  --admin_user ${KEYSTONE_ADMIN_USER} \
    --admin_password ${KEYSTONE_ADMIN_PASSWORD} --admin_tenant_name ${KEYSTONE_ADMIN_TENANT}

# Register database in config
retry /usr/share/contrail-utils/provision_database_node.py --api_server_ip $API_SERVER_IP \
    --host_name ${MYHOSTNAME} --host_ip ${DATABASE_IP} --oper add \
    --admin_user ${KEYSTONE_ADMIN_USER} --admin_password ${KEYSTONE_ADMIN_PASSWORD} \
     --admin_tenant_name ${KEYSTONE_ADMIN_TENANT}

##
# Register control node objects
##
# Add ASN to global system config
retry /usr/share/contrail-utils/provision_control.py --api_server_ip ${API_SERVER_IP} \
    --api_server_port ${API_SERVER_PORT} --router_asn ${ROUTER_ASN}  --admin_user ${KEYSTONE_ADMIN_USER} \
    --admin_password ${KEYSTONE_ADMIN_PASSWORD} --admin_tenant_name ${KEYSTONE_ADMIN_TENANT}

# Add the node as a BGP speaker
if [[ $BGP_MD5 ]]; then
    md5_param=" --md5 $BGP_MD5 "
fi

retry /usr/share/contrail-utils/provision_control.py --api_server_ip ${API_SERVER_IP} \
    --api_server_port ${API_SERVER_PORT} --router_asn ${ROUTER_ASN}  --admin_user ${KEYSTONE_ADMIN_USER} \
    --admin_password ${KEYSTONE_ADMIN_PASSWORD} --admin_tenant_name ${KEYSTONE_ADMIN_TENANT} ${md5_param} \
    --host_name $MYHOSTNAME --host_ip ${CONTROL_IP} --oper add

# Add external routers if any
# EXTERNAL_ROUTERS_LIST is a space delimited list of routers in form of routername:ipaddress
for ext_router in  $EXTERNAL_ROUTERS_LIST; do
    # ext_router will be in the form of <hostname>:<ipaddress>
    ext_router_name=${ext_router%:*}
    ext_router_ip=${ext_router#*:}
    retry /usr/share/contrail-utils/provision_mx.py --api_server_ip ${API_SERVER_IP} \
        --api_server_port ${API_SERVER_PORT} --router_name ${ext_router_name} \
        --router_ip ${ext_router_ip} --router_asn $ROUTER_ASN --admin_user ${KEYSTONE_ADMIN_USER} \
        --admin_password ${KEYSTONE_ADMIN_PASSWORD} --admin_tenant_name ${KEYSTONE_ADMIN_TENANT}
done


wait "$child"
