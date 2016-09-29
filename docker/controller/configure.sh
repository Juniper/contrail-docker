#!/usr/bin/env bash

source /env.sh

# Functions
function setup_rabbitmq() {
    rabbitmq_server_list_w_port=$(echo $rabbitmq_server_ip_list | sed 's/, *$//' |\
        sed -r -e "s/[, ]+/:$RABBITMQ_SERVER_PORT,/g" -e "s/$/:$RABBITMQ_SERVER_PORT/")

    # Setup rabbitmq-env.conf
    cat <<EOF > /etc/rabbitmq/rabbitmq-env.conf
NODE_IP_ADDRESS=$RABBITMQ_LISTEN_IP
NODENAME=rabbit@${MYHOSTNAME}-ctrl
EOF
    # Determine node's index based on IP address
    rabbit_servers_sorted=$(echo $RABBITMQ_SERVER_LIST | sed -r 's/\s+/\n/g' | sort -V)
    index=$(echo "$rabbit_servers_sorted" | grep -n "${RABBITMQ_LISTEN_IP}:" | cut -f1 -d:)

    # Setup rabbitmq.config
    pyj2.py -t /rabbitmq.conf.j2 -o /etc/rabbitmq/rabbitmq.config

    service rabbitmq-server stop
    if [[ `epmd -kill | grep -c "Killed"` -eq 0 ]]; then
        pkill -9  beam;
        pkill -9  epmd
        if [ `netstat -anp | grep -c beam` -ne 0 ]; then
            pkill -9 beam
        fi
    fi
    # Remove rabbitmq mnesia database, set erlang cookie
    rm -rf /var/lib/rabbitmq/mnesia
    echo $RABBITMQ_CLUSTER_UUID > /var/lib/rabbitmq/.erlang.cookie
    chmod 400 /var/lib/rabbitmq/.erlang.cookie
    chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
    service rabbitmq-server restart
        # All nodes except first node will wait till first node is up
    if [[ $index > 1 ]]; then
        first_ip=$(echo "$rabbit_servers_sorted" | cut -f1 -d: | head -1)
        first_server_name=$(echo "$rabbit_servers_sorted" | cut -f2 -d: | head -1)
        wait_for_service_port $first_ip  $RABBITMQ_SERVER_PORT
        rabbitmqctl stop_app
        rabbitmqctl join_cluster rabbit@${first_server_name}-ctrl
        rabbitmqctl start_app
    fi
    # adding sleep to workaround rabbitmq bug 26370 prevent
    # "rabbitmqctl cluster_status" from breaking the database,
    # this is seen in ci
    # 2016-07-03 Harish: Lets confirm this is happening in current environment
    #sleep 30
    rabbitmqctl set_policy HA-all "" '{"ha-mode":"all","ha-sync-mode":"automatic"}'
    service rabbitmq-server stop
}

## WEBUI configuration
function configure_webui() {
    cassandra_servers_as_array=$(echo $CASSANDRA_SERVER_LIST | sed -r -e "s/^/['/" -e  "s/[, ]+/', '/g" -e "s/$/']/")
    webui_config config.cnfg.server_ip "'$API_SERVER_IP'"
    webui_config config.networkManager.ip "'$API_SERVER_IP'"
    webui_config config.imageManager.ip "'$OPENSTACK_IP'"
    webui_config config.computeManager.ip "'$OPENSTACK_IP'"
    webui_config config.identityManager.ip "'$KEYSTONE_SERVER'"
    webui_config config.storageManager.ip "'$OPENSTACK_IP'"
    webui_config config.analytics.server_ip "'$ANALYTICS_SERVER'"
    webui_config config.cassandra.server_ips "$cassandra_servers_as_array"
    webui_config config.redis_password "'$REDIS_PASSWORD'"
    if [[ $CLOUD_ORCHESTRATOR == "openstack" ]]; then
        webui_config config.orchestration.Manager "'openstack'"
    elif [[ $CLOUD_ORCHESTRATOR == "vcenter" ]]; then
        webui_config config.orchestration.Manager "'vcenter'"
        webui_config config.vcenter.server_ip "'$VCENTER_SERVER_IP'"
        webui_config config.vcenter.server_port "'$VCENTER_SERVER_PORT'"
        webui_config config.vcenter.authProtocol "'$VCENTER_AUTH_PROTOCOL'"
        webui_config config.vcenter.datacenter "'$VCENTER_DATACENTER'"
        webui_config config.vcenter.dvsswitch "'$VCENTER_DVSWITCH'"
        webui_config config.multi_tenancy "{}"
        webui_config config.multi_tenancy.enabled "false"
    else
        webui_config config.orchestration.Manager "'none'"
        webui_config config.multi_tenancy "{}"
        webui_config config.multi_tenancy.enabled "false"
    fi
}

function setup_config () {
    # Setup ifmap_server/basicauthusers.properties
    for i in `echo $CONTROL_SERVER_LIST | sed 's/,\s*/ /'`; do
        sed -i "/^${i}:/{h;s/:.*/:${i}/};\${x;/^\$/{s//${i}:${i}/;H};x}" /etc/ifmap-server/basicauthusers.properties
        sed -i "/^${i}.dns:/{h;s/:.*/:${i}.dns/};\${x;/^\$/{s//${i}.dns:${i}.dns/;H};x}" /etc/ifmap-server/basicauthusers.properties
    done
    # END ifmap_server/basicauthusers.properties

    # Setup /etc/contrail/contrail-config-nodemgr.conf
    setcfg /etc/contrail/contrail-config-nodemgr.conf
    setsection DISCOVERY
    setini server $DISCOVERY_SERVER
    setini port $DISCOVERY_SERVER_PORT
    # END setup /etc/contrail/contrail-config-nodemgr.conf

    # Setup contrail-api.conf
    setcfg /etc/contrail/contrail-api.conf
    setsection DEFAULTS
    setini ifmap_server_ip $IFMAP_SERVER
    setini ifmap_server_port $IFMAP_SERVER_PORT
    setini ifmap_username $IFMAP_USERNAME
    setini ifmap_password $IFMAP_PASSWORD
    setini cassandra_server_list $cassandra_server_list_w_port
    setini listen_ip_addr $API_SERVER_LISTEN
    setini listen_port $API_SERVER_LISTEN_PORT
    setini multi_tenancy $MULTI_TENANCY
    setini log_file $API_SERVER_LOG_FILE
    setini log_local 1
    setini log_level $API_SERVER_LOG_LEVEL
    setini disc_server_ip $DISCOVERY_SERVER
    setini disc_server_port $DISCOVERY_SERVER_PORT
    setini zk_server_ip $zk_server_list_w_port
    setini rabbit_server $rabbitmq_server_list_w_port
    setini list_optimization_enabled True
    setini auth "keystone"

    setsection "SECURITY"
    setini use_certs False
    setini keyfile /etc/contrail/ssl/private_keys/apiserver_key.pem
    setini certfile "/etc/contrail/ssl/certs/apiserver.pem"
    setini ca_certs "/etc/contrail/ssl/certs/ca.pem"
    # END contrail-api.conf setup


    # Setup /etc/contrail/contrail-schema.conf
    setcfg /etc/contrail/contrail-schema.conf
    setsection "DEFAULTS"
    setini ifmap_server_ip $IFMAP_SERVER
    setini ifmap_server_port $IFMAP_SERVER_PORT
    setini ifmap_username $IFMAP_USERNAME
    setini ifmap_password $IFMAP_PASSWORD
    setini cassandra_server_list $cassandra_server_list_w_port
    setini api_server_ip $API_SERVER_IP
    setini api_server_port $API_SERVER_PORT
    setini api_server_use_ssl $API_SERVER_USE_SSL
    setini log_file $SCHEMA_LOG_FILE
    setini log_local 1
    setini log_level $SCHEMA_LOG_LEVEL
    setini disc_server_ip $DISCOVERY_SERVER
    setini disc_server_port $DISCOVERY_SERVER_PORT
    setini zk_server_ip $zk_server_list_w_port
    setini rabbit_server $rabbitmq_server_list_w_port

    setsection "SECURITY"
    setini use_certs "False"
    setini keyfile "/etc/contrail/ssl/private_keys/schema_xfer_key.pem"
    setini certfile "/etc/contrail/ssl/certs/schema_xfer.pem"
    setini ca_certs "/etc/contrail/ssl/certs/ca.pem"
    # END /etc/contrail/contrail-schema.conf setup

    # Setup /etc/contrail/contrail-discovery.conf
    setcfg /etc/contrail/contrail-discovery.conf
    setsection "DEFAULTS"
    setini zk_server_ip $ZOOKEEPER_SERVER_LIST
    setini zk_server_port $ZOOKEEPER_SERVER_PORT
    setini listen_ip_addr $DISCOVERY_SERVER_LISTEN
    setini listen_port $DISCOVERY_SERVER_LISTEN_PORT
    setini log_local "True"
    setini log_file $DISCOVERY_LOG_FILE
    setini log_level $DISCOVERY_LOG_LEVEL
    setini cassandra_server_list $cassandra_server_list_w_port
    setini ttl_min $DISCOVERY_TTL_MIN
    setini ttl_max $DISCOVERY_TTL_MAX
    setini hc_interval $DISCOVERY_HC_INTERVAL
    setini hc_max_miss $DISCOVERY_HC_MAX_MISS
    setini ttl_short $DISCOVERY_TTL_SHORT

    setsection "DNS-SERVER"
    setini policy "fixed"
    # END /etc/contrail/contrail-discovery.conf setup


    # Setup /etc/contrail/contrail-svc-monitor.conf
    setcfg /etc/contrail/contrail-svc-monitor.conf
    setsection "DEFAULTS"
    setini ifmap_server_ip $IFMAP_SERVER
    setini ifmap_server_port $IFMAP_SERVER_PORT
    setini ifmap_username $IFMAP_USERNAME
    setini ifmap_password $IFMAP_PASSWORD
    setini cassandra_server_list $cassandra_server_list_w_port
    setini api_server_ip $API_SERVER_IP
    setini api_server_port $API_SERVER_PORT
    setini api_server_use_ssl $API_SERVER_USE_SSL
    setini log_file $SVC_MONITOR_LOG_FILE
    setini log_local 1
    setini log_level $SVC_MONITOR_LOG_LEVEL
    setini disc_server_ip $DISCOVERY_SERVER
    setini disc_server_port $DISCOVERY_SERVER_PORT
    setini zk_server_ip $zk_server_list_w_port
    setini rabbit_server $rabbitmq_server_list_w_port
    setini region_name $REGION

    setsection "SECURITY"
    setini use_certs False
    setini keyfile /etc/contrail/ssl/private_keys/svc_monitor_key.pem
    setini certfile /etc/contrail/ssl/certs/svc_monitor.pem
    setini ca_certs /etc/contrail/ssl/certs/ca.pem

    setsection "SCHEDULER"
    setini analytics_server_ip $ANALYTICS_SERVER
    setini analytics_server_port $ANALYTICS_SERVER_PORT
    # END /etc/contrail/contrail-svc-monitor.conf setup

    # Setup  /etc/contrail/contrail-device-manager.conf
    setcfg /etc/contrail/contrail-device-manager.conf
    setsection "DEFAULTS"
    setini rabbit_server $rabbitmq_server_list_w_port
    setini api_server_ip $API_SERVER_IP
    setini api_server_port $API_SERVER_PORT
    setini api_server_use_ssl $API_SERVER_USE_SSL
    setini zk_server_ip $zk_server_list_w_port
    setini log_file $DEVICE_MANAGER_LOG_FILE
    setini log_level $DEVICE_MANAGER_LOG_LEVEL
    setini log_local 1
    setini cassandra_server_list $cassandra_server_list_w_port
    setini disc_server_ip $DISCOVERY_SERVER
    setini disc_server_port $DISCOVERY_PORT
    # END Setup  /etc/contrail/contrail-device-manager.conf

    setup_keystone_auth_config
    setup_vnc_api_lib

    # Handle changes of IFMAP_SERVER_PORT in ifmap server configuration
    sed -i "s/^irond.comm.basicauth.port=.*/irond.comm.basicauth.port=${IFMAP_SERVER_PORT}/" /etc/ifmap-server/ifmap.properties

    # Below steps only required for openstack
    if [[ $CLOUD_ORCHESTRATOR == "openstack" ]]; then
        # Setup /etc/neutron/plugins/opencontrail/ContrailPlugin.ini
        setcfg /etc/neutron/plugins/opencontrail/ContrailPlugin.ini
        setsection "APISERVER"
        setini api_server_ip $API_SERVER_IP
        setini api_server_port $API_SERVER_PORT
        setini multi_tenancy $MULTI_TENANCY
        setini use_ssl $API_SERVER_USE_SSL
        setini insecure $API_SERVER_INSECURE
        setini contrail_extensions $NEUTRON_CONTRAIL_EXTENSIONS

        setsection "COLLECTOR"
        setini analytics_api_ip $ANALYTICS_SERVER
        setini analytics_api_port $ANALYTICS_SERVER_PORT

        setsection "KEYSTONE"
        setini auth_url ${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_SERVER}:${KEYSTONE_AUTH_PORT}/v2.0
        setini admin_user $KEYSTONE_ADMIN_USER
        setini admin_password $KEYSTONE_ADMIN_PASSWORD
        setini admin_tenant_name $KEYSTONE_ADMIN_TENANT
        # END /etc/neutron/plugins/opencontrail/ContrailPlugin.ini

        # setup neutron endpoints - this is bit tricky, currently we use setup-quantum-in-keystone
        # to setup neutron endpoints in keystone, and that script doesnt handle simultaneous executions.
        # So only one neutron container should run this.
        neutron_servers_sorted=$(echo $NEUTRON_SERVER_LIST | sed -r 's/\s+/\n/g' | sort -V)
        neutron_index=$(echo "$neutron_servers_sorted" | grep -ne "${IPADDRESS}$" | cut -f1 -d:)

        if [[ $neutron_index == 1 ]]; then
            wait_for_url ${KEYSTONE_AUTH_PROTOCOL}://$KEYSTONE_SERVER:${KEYSTONE_AUTH_PORT}
            /opt/contrail/bin/setup-quantum-in-keystone --ks_server_ip $KEYSTONE_SERVER  \
                --quant_server_ip $NEUTRON_IP --tenant $KEYSTONE_ADMIN_TENANT \
                --user $KEYSTONE_ADMIN_USER --password $KEYSTONE_ADMIN_PASSWORD \
                --svc_password $NEUTRON_PASSWORD --svc_tenant_name $SERVICE_TENANT \
                --region_name $REGION
        fi

        # Start neutron
        # TODO: neutron need to be added to supervisord
        /opt/contrail/bin/quantum-server-setup.sh
    fi

}

function configure_control() {
    ##
    # Configure control services
    ##
    # Setup contrail-control.conf

    setcfg "/etc/contrail/contrail-control.conf"
    setsection DEFAULT
    setini hostip $IPADDRESS
    setini hostname $MYHOSTNAME
    setini log_file $CONTROL_LOG_FILE
    setini log_level $CONTROL_LOG_LEVEL
    setini log_local 1

    setsection DISCOVERY
    setini server $DISCOVERY_SERVER

    setsection IFMAP
    setini user $CONTROL_IFMAP_USER
    setini password $CONTROL_IFMAP_PASSWORD
    setini certs_store $CONTROL_CERTS_STORE

    # End contrail-control.conf setup

    # Setup contrail-dns.conf
    setcfg "/etc/contrail/contrail-dns.conf"
    setsection "DEFAULT"
    setini hostip $IPADDRESS
    setini hostname $MYHOSTNAME
    setini log_file $DNS_LOG_FILE
    setini log_level $DNS_LOG_LEVEL
    setini log_local 1

    setsection DISCOVERY
    setini server $DISCOVERY_SERVER

    setsection "IFMAP"
    setini user $DNS_IFMAP_USER
    setini password $DNS_IFMAP_PASSWORD
    setini certs_store $CONTROL_CERTS_STORE
    # END contrail-dns.conf


    # Setup contrail-control-nodemgr.conf
    setcfg "/etc/contrail/contrail-control-nodemgr.conf"
    setsection "DISCOVERY"
    setini server $DISCOVERY_SERVER
    setini port $DISCOVERY_PORT
    # END contrail-control-nodemgr.conf

}
# Main code start here

cassandra_server_list_w_port=$(echo $CASSANDRA_SERVER_LIST | sed -r -e "s/[, ]+/:$CASSANDRA_SERVER_PORT /g" -e "s/$/:$CASSANDRA_SERVER_PORT/")
zk_server_list_w_port=$(echo $ZOOKEEPER_SERVER_LIST | sed -r -e "s/[, ]+/:$ZOOKEEPER_SERVER_PORT,/g" -e "s/$/:$ZOOKEEPER_SERVER_PORT/")
rabbitmq_server_list_w_port=$(echo $RABBITMQ_SERVER_LIST | sed -r -e "s/[, ]+/:$RABBITMQ_SERVER_PORT,/g" -e "s/$/:$RABBITMQ_SERVER_PORT/")
## Rabbitmq server configuration
# Setup /etc/hosts entries for all rabbitmq hostnames (and hostname-ctrl name) - it is not required if those
# names are resolvable using dns but it is not expected here

for rabbitmq_server in `echo $RABBITMQ_SERVER_LIST | sed -r 's/[, ]/ /g'`; do
    if [[ $rabbitmq_server =~ : ]]; then
        ip=${rabbitmq_server%:*}
        hostname=${rabbitmq_server#*:}
        rabbitmq_server_ip_list+="$ip,"
        rabbitmq_servername_list+="$hostname,"

        if [[ `grep -c "${hostname}-ctrl" /etc/hosts` -eq 0 ]]; then
            echo "$ip $hostname ${hostname}-ctrl" >> /etc/hosts
        fi
    fi
done

rabbitmq_server_ip_list=${rabbitmq_server_ip_list/%,/}
rabbitmq_servername_list=${rabbitmq_servername_list/%,/}

if [[ $DISABLE_RABBITMQ != "yes" ]]; then
    setup_rabbitmq
fi


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

ansible_extra_vars+=" webui_http_listen_port=$WEBUI_HTTP_LISTEN_PORT"
ansible_extra_vars+=" webui_https_listen_port=$WEBUI_HTTPS_LISTEN_PORT"
ansible_extra_vars+=" ifmap_server_port=$IFMAP_SERVER_PORT"

cd /contrail-ansible/playbooks/
ansible-playbook -i inventory/$ANSIBLE_INVENTORY \
 -t provision,configure contrail_controller.yml -e "$ansible_extra_vars"

setup_keystone_auth_config
setup_vnc_api_lib

# FIXME - would need to create secret rather than accept it as variable. Also may be it need better regex
#   to handle multiple space etc
for file in /etc/contrail/dns/contrail-rndc.conf /etc/contrail/dns/contrail-named.conf; do
    sed -i 's/secret \"secret123\";/secret \"${DNS_RNDC_KEY}\";/g' $file
done
