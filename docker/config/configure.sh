#!/usr/bin/env bash

. common.sh

export PATH=$PATH:/opt/contrail/bin

IPADDRESS=${IPADDRESS:-127.0.0.1}

CONFIG_IP=${CONFIG_IP:-$IPADDRESS}

CONTRAIL_INTERNAL_VIP=${CONTRAIL_INTERNAL_VIP}
OPENSTACK_INTERNAL_VIP=${OPENSTACK_INTERNAL_VIP}

API_SERVER_LISTEN=${API_SERVER_LISTEN:-0.0.0.0}
API_SERVER_LISTEN_PORT=${API_SERVER_LISTEN_PORT:-9100}
API_SERVER_IP=${API_SERVER_IP:-${CONTRAIL_INTERNAL_VIP:-$CONFIG_IP}}
API_SERVER_PORT=${API_SERVER_PORT:-8082}
API_SERVER_USE_SSL=${API_SERVER_USE_SSL:-"False"}
MULTI_TENANCY=${MULTI_TENANCY:-True}
API_SERVER_LOG_FILE=${API_SERVER_LOG_FILE:-"/var/log/contrail/contrail-api.log"}
API_SERVER_LOG_LEVEL=${API_SERVER_LOG_LEVEL:-"SYS_NOTICE"}
API_SERVER_INSECURE=${API_SERVER_INSECURE:-"False"}
SCHEMA_LOG_FILE=${SCHEMA_LOG_FILE:-"/var/log/contrail/contrail-schema.log"}
SCHEMA_LOG_LEVEL=${SCHEMA_LOG_LEVEL:-SYS_NOTICE}

RABBITMQ_SERVER_LIST=${RABBITMQ_SERVER_LIST:-$IPADDRESS}
RABBITMQ_SERVER_PORT=${RABBITMQ_SERVER_PORT:-5672}

ANALYTICS_SERVER=${ANALYTICS_SERVER:-${CONTRAIL_INTERNAL_VIP:-$IPADDRESS}}
ANALYTICS_SERVER_PORT=${ANALYTICS_SERVER_PORT:-8081}

CASSANDRA_SERVER_LIST=${CASSANDRA_SERVER_LIST:-$IPADDRESS}
CASSANDRA_SERVER_PORT=${CASSANDRA_SERVER_PORT:-9160}
ZOOKEEPER_SERVER_LIST=${ZOOKEEPER_SERVER_LIST:-$IPADDRESS}
ZOOKEEPER_SERVER_PORT=${ZOOKEEPER_SERVER_PORT:-2181}
CONTROL_SERVER_LIST=${CONTROL_SERVER_LIST:-$IPADDRESS}

IFMAP_SERVER=${IFMAP_SERVER:-$IPADDRESS}
IFMAP_SERVER_PORT=${IFMAP_SERVER_PORT:-8443}
IFMAP_USERNAME=${IFMAP_USERNAME:-"api-server"}
IFMAP_PASSWORD=${IFMAP_PASSWORD:-"api-server"}

DISCOVERY_SERVER=${DISCOVERY_SERVER:-${CONTRAIL_INTERNAL_VIP:-$CONFIG_IP}}
DISCOVERY_SERVER_LISTEN=${DISCOVERY_SERVER_LISTEN:-"0.0.0.0"}
DISCOVERY_SERVER_LISTEN_PORT=${DISCOVERY_SERVER_LISTEN_PORT:-9110}
DISCOVERY_SERVER_PORT=${DISCOVERY_SERVER_PORT:-5998}
DISCOVERY_LOG_FILE=${DISCOVERY_LOG_FILE:-"/var/log/contrail/contrail-discovery.log"}
DISCOVERY_LOG_LEVEL=${DISCOVERY_LOG_LEVEL:-"SYS_NOTICE"}
DISCOVERY_TTL_MIN=${DISCOVERY_TTL_MIN:-300}
DISCOVERY_TTL_MAX=${DISCOVERY_TTL_MAX:-1800}
DISCOVERY_HC_INTERVAL=${DISCOVERY_HC_INTERVAL:-5}
DISCOVERY_HC_MAX_MISS=${DISCOVERY_HC_MAX_MISS:-3}
DISCOVERY_TTL_SHORT=${DISCOVERY_TTL_SHORT:-1}
DISCOVERY_DNS_SERVER_POLICY=${DISCOVERY_DNS_SERVER_POLICY:-fixed}

SVC_MONITOR_LOG_FILE=${SVC_MONITOR_LOG_FILE:-"/var/log/contrail/contrail-svc-monitor.log"}
SVC_MONITOR_LOG_LEVEL=${SVC_MONITOR_LOG_LEVEL:-SYS_NOTICE}


COLLECTOR_SERVER=${COLLECTOR_SERVER:-${CONTRAIL_INTERNAL_VIP:-$CONFIG_IP}}

KEYSTONE_SERVER=${KEYSTONE_SERVER:-${OPENSTACK_INTERNAL_VIP:-$IPADDRESS}}

SERVICE_TENANT=${SERVICE_TENANT:-service}
KEYSTONE_AUTH_PROTOCOL=${KEYSTONE_AUTH_PROTOCOL:-http}
KEYSTONE_AUTH_PORT=${KEYSTONE_AUTH_PORT:-35357}
KEYSTONE_INSECURE=${KEYSTONE_INSECURE:-False}
KEYSTONE_ADMIN_USER=${OS_USERNAME:-admin}
KEYSTONE_ADMIN_PASSWORD=${OS_PASSWORD:-admin}
KEYSTONE_ADMIN_TENANT=${OS_TENANT_NAME:-admin}
KEYSTONE_ADMIN_TOKEN=${OS_TOKEN:-$ADMIN_TOKEN}
REGION=${REGION:-RegionOne}

NEUTRON_IP=${NEUTRON_IP:-${CONTRAIL_INTERNAL_VIP:-$CONFIG_IP}}
NEUTRON_PORT=${NEUTRON_PORT:-9697}
NEUTRON_USER=${NEUTRON_USER:-neutron}
NEUTRON_PASSWORD=${NEUTRON_PASSWORD:-neutron}
NEUTRON_PROTOCOL=${KEYSTONE_AUTH_PROTOCOL:-http}
$CONTRAIL_EXTENSIONS_DEFAULTS="ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam,policy:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_policy.NeutronPluginContrailPolicy,route-table:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_vpc.NeutronPluginContrailVpc,contrail:None"
NEUTRON_CONTRAIL_EXTENSIONS=${NEUTRON_CONTRAIL_EXTENSIONS:-$CONTRAIL_EXTENSIONS_DEFAULTS}

cassandra_server_list_w_port=$(echo $CASSANDRA_SERVER_LIST | sed -r -e "s/[, ]+/:$CASSANDRA_SERVER_PORT /g" -e "s/$/:$CASSANDRA_SERVER_PORT/")
zk_server_list_w_port=$(echo $ZOOKEEPER_SERVER_LIST | sed -r -e "s/[, ]+/:$ZOOKEEPER_SERVER_PORT,/g" -e "s/$/:$ZOOKEEPER_SERVER_PORT/")
rabbitmq_server_list_w_port=$(echo $RABBITMQ_SERVER_LIST | sed -r -e "s/[, ]+/:$RABBITMQ_SERVER_PORT,/g" -e "s/$/:$RABBITMQ_SERVER_PORT/")


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

setup_keystone_auth_config
setup_vnc_api_lib

# Create service endpoints et al
/opt/contrail/bin/setup-quantum-in-keystone --ks_server_ip $KEYSTONE_SERVER --quant_server_ip $NEUTRON_IP \
    --tenant $KEYSTONE_ADMIN_TENANT --user $KEYSTONE_ADMIN_USER --password $KEYSTONE_ADMIN_PASSWORD \
    --svc_password $NEUTRON_PASSWORD --svc_tenant_name $SERVICE_TENANT --region_name $REGION

cat <<EOF > /etc/contrail/ctrl-details
SERVICE_TOKEN=$KEYSTONE_ADMIN_TOKEN
AUTH_PROTOCOL=$KEYSTONE_AUTH_PROTOCOL
QUANTUM_PROTOCOL=$NEUTRON_PROTOCOL
ADMIN_TOKEN=$KEYSTONE_ADMIN_PASSWORD
CONTROLLER=$API_SERVER_IP
AMQP_SERVER=$RABBITMQ_SERVER_LIST
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

# Start neutron
# TODO: neutron need to be added to supervisord
/opt/contrail/bin/quantum-server-setup.sh
