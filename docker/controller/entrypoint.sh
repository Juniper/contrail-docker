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

function write_ctrl_details() {
cat <<EOF > /etc/contrail/ctrl-details
SERVICE_TOKEN=$KEYSTONE_ADMIN_TOKEN
AUTH_PROTOCOL=$KEYSTONE_AUTH_PROTOCOL
QUANTUM_PROTOCOL=$NEUTRON_PROTOCOL
ADMIN_TOKEN=$KEYSTONE_ADMIN_PASSWORD
CONTROLLER=$KEYSTONE_SERVER
AMQP_SERVER=$rabbitmq_server_list_w_port
HYPERVISOR=libvirt
NOVA_PASSWORD=$NEUTRON_PASSWORD
NEUTRON_PASSWORD=$NEUTRON_PASSWORD
SERVICE_TENANT_NAME=$SERVICE_TENANT
SERVICE_TENANT=$SERVICE_TENANT
QUANTUM=$NEUTRON_IP
QUANTUM_PORT=$NEUTRON_PORT
COMPUTE=$KEYSTONE_SERVER
CONTROLLER_MGMT=$API_SERVER_IP
EOF
}


function pre_start() {
    ulimit -s unlimited
    ulimit -c unlimited
    ulimit -d unlimited
    ulimit -v unlimited
    ulimit -n 4096
    chown -R cassandra.cassandra /var/lib/cassandra
    chown -R zookeeper.zookeeper /var/lib/zookeeper
    # Write ctrl-details file
    write_ctrl_details
    # configure services and start them using ansible code within contrail-ansible
    contrailctl config sync -c controller -F

    # Setup keystone configuration (only required for openstack setup
    setup_keystone_auth_config
    setup_vnc_api_lib

    # FIXME - This must be moved to contrail-ansible
    for file in /etc/contrail/dns/contrail-rndc.conf /etc/contrail/dns/contrail-named.conf; do
        sed -i 's/secret \"secret123\";/secret \"${DNS_RNDC_KEY}\";/g' $file
    done
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
# run contrailctl to run code to make sure services are running
contrailctl config sync -c controller -F -t service

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
