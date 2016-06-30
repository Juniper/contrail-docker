#!/usr/bin/env bash

. common.sh

IPADDRESS=${IPADDRESS:-127.0.0.1}

KAFKA_BROKER_LIST=${KAFKA_BROKER_LIST:-$IPADDRESS}
KAFKA_PORT=${KAFKA_PORT:-9092}

ZOOKEEPER_SERVER_LIST=${ZOOKEEPER_SERVER_LIST:-$IPADDRESS}
ZOOKEEPER_SERVER_PORT=${ZOOKEEPER_SERVER_PORT:-2181}

CASSANDRA_SERVER_LIST=${CASSANDRA_SERVER_LIST:-$IPADDRESS}
CASSANDRA_SERVER_PORT=${CASSANDRA_SERVER_PORT:-9160}

ALARM_GEN_LOG_FILE=${CONTROL_LOG_FILE:-"/var/log/contrail/contrail-alarm-gen.log"}
ALARM_GEN_LOG_LEVEL=${CONTROL_LOG_LEVEL:-"SYS_NOTICE"}

COLLECTOR_INTROSPECT_PORT=${COLLECTOR_INTROSPECT_PORT:-8089}
COLLECTOR_PORT=${COLLECTOR_PORT:-8086}
COLLECTOR_LOG_FILE=${COLLECTOR_LOG_FILE:-"/var/log/contrail/contrail-collector.log"}
COLLECTOR_LOG_LEVEL=${COLLECTOR_LOG_LEVEL:-"SYS_NOTICE"}

QUERY_ENGINE_INTROSPECT_PORT=${QUERY_ENGINE_INTROSPECT_PORT:-8091}
QUERY_ENGINE_LOG_FILE=${QUERY_ENGINE_LOG_FILE:-"/var/log/contrail/contrail-query-engine.log"}
QUERY_ENGINE_LOG_LEVEL=${QUERY_ENGINE_LOG_LEVEL:-"SYS_NOTICE"}

ANALYTICS_API_INTROSPECT_PORT=${ANALYTICS_API_INTROSPECT_PORT:-8090}
ANALYTICS_API_PORT=${ANALYTICS_API_PORT:-8081}
ANALYTICS_API_LISTEN_IP=${ANALYTICS_API_LISTEN_IP:-"0.0.0.0"}
ANALYTICS_API_LOG_FILE=${ANALYTICS_API_LOG_FILE:-"/var/log/contrail/contrail-analytics-api.log"}
ANALYTICS_API_LOG_LEVEL=${ANALYTICS_API_LOG_LEVEL:-"SYS_NOTICE"}

SNMP_COLLECTOR_LISTEN_IP=${SNMP_COLLECTOR_LISTEN_IP:-"0.0.0.0"}
SNMP_COLLECTOR_INTROSPECT_PORT=${SNMP_COLLECTOR_INTROSPECT_PORT:-5920}
SNMP_COLLECTOR_LOG_FILE=${SNMP_COLLECTOR_LOG_FILE:-"/var/log/contrail/contrail-snmp-collector.log"}
SNMP_COLLECTOR_LOG_LEVEL=${SNMP_COLLECTOR_LOG_LEVEL:-"SYS_NOTICE"}

TOPOLOGY_INTROSPECT_PORT=${TOPOLOGY_INTROSPECT_PORT:-5921}
TOPOLOGY_LOG_FILE=${TOPOLOGY_LOG_FILE:-"/var/log/contrail/contrail-topology.log"}
TOPOLOGY_LOG_LEVEL=${TOPOLOGY_LOG_LEVEL:-"SYS_NOTICE"}

ANALYTICS_DATA_TTL=${ANALYTICS_DATA_TTL:-48}
ANALYTICS_CONFIG_AUDIT_TTL=${ANALYTICS_CONFIG_AUDIT_TTL:-$ANALYTICS_DATA_TTL}
ANALYTICS_STATISTICS_TTL=${ANALYTICS_STATISTICS_TTL:-$ANALYTICS_DATA_TTL}
ANALYTICS_FLOW_TTL=${ANALYTICS_FLOW_TTL:-$ANALYTICS_DATA_TTL}

DISCOVERY_SERVER=${DISCOVERY_SERVER:-$IPADDRESS}
DISCOVERY_PORT=${DISCOVERY_PORT:-5998}

REDIS_SERVER=${REDIS_SERVER:-$IPADDRESS}
REDIS_SERVER_PORT=${REDIS_SERVER_PORT:-6379}

KEYSTONE_SERVER=${KEYSTONE_SERVER:-$IPADDRESS}

KEYSTONE_AUTH_PROTOCOL=${KEYSTONE_AUTH_PROTOCOL:-http}
KEYSTONE_AUTH_PORT=${KEYSTONE_AUTH_PORT:-35357}
KEYSTONE_INSECURE=${KEYSTONE_INSECURE:-False}
KEYSTONE_ADMIN_USER=${OS_USERNAME:-admin}
KEYSTONE_ADMIN_PASSWORD=${OS_PASSWORD:-admin}
KEYSTONE_ADMIN_TENANT=${OS_TENANT_NAME:-admin}

REGION=${REGION:-RegionOne}

cassandra_server_list_w_port=$(echo $CASSANDRA_SERVER_LIST | sed -r -e "s/[, ]+/:$CASSANDRA_SERVER_PORT /g" -e "s/$/:$CASSANDRA_SERVER_PORT/")
zk_server_list_w_port=$(echo $ZOOKEEPER_SERVER_LIST | sed -r -e "s/[, ]+/:$ZOOKEEPER_SERVER_PORT,/g" -e "s/$/:$ZOOKEEPER_SERVER_PORT/")
rabbitmq_server_list_w_port=$(echo $RABBITMQ_SERVER_LIST | sed -r -e "s/[, ]+/:$RABBITMQ_SERVER_PORT,/g" -e "s/$/:$RABBITMQ_SERVER_PORT/")


# Setup /etc/contrail/contrail-alarm-gen.conf
setcfg /etc/contrail/contrail-alarm-gen.conf
setsection "DEFAULTS"
setini host_ip $IPADDRESS
setini log_file $ALARM_GEN_LOG_FILE
setini log_level $ALARM_GEN_LOG_LEVEL
setini log_local 1
setini kafka_broker_list $kafka_broker_list_w_port
setini zk_list $zk_server_list_w_port

setsection "DISCOVERY"
setini disc_server_ip $DISCOVERY_SERVER
setini disc_server_port $DISCOVERY_PORT

setsection "REDIS"
setini redis_server_port $REDIS_SERVER_PORT
setini redis_server_ip $REDIS_SERVER
# END /etc/contrail/contrail-alarm-gen.conf setup

# Setup /etc/contrail/contrail-collector.conf
setcfg /etc/contrail/contrail-collector.conf
setsection "DEFAULT"
setini cassandra_server_list $cassandra_server_list_w_port
setini zookeeper_server_list $zk_server_list_w_port
setini kafka_broker_list $kafka_broker_list_w_port
setini hostip $IPADDRESS
setini http_server_port $COLLECTOR_INTROSPECT_PORT
setini log_file $COLLECTOR_LOG_FILE
setini log_local 1
setini syslog_port -1

setsection "COLLECTOR"
setini port $COLLECTOR_PORT
setini disc_server_port $DISCOVERY_PORT

setsection "DISCOVERY"
setini server $DISCOVERY_SERVER
setini port $DISCOVERY_PORT

setsection "REDIS"
setini port $REDIS_SERVER_PORT
setini server $REDIS_SERVER

# Setup /etc/contrail/contrail-query-engine.conf
setcfg /etc/contrail/contrail-query-engine.conf
setsection "DEFAULT"
setini analytics_data_ttl $ANALYTICS_DATA_TTL
setini cassandra_server_list $cassandra_server_list_w_port
setini host_ip $IPADDRESS
setini http_server_port $QUERY_ENGINE_INTROSPECT_PORT
setini log_local 1
setini log_level $QUERY_ENGINE_LOG_LEVEL
setini log_file $QUERY_ENGINE_LOG_FILE

setsection "DISCOVERY"
setini server $DISCOVERY_SERVER
setini port $DISCOVERY_PORT

setsection "REDIS"
setini port $REDIS_SERVER_PORT
setini server $REDIS_SERVER
# END /etc/contrail/contrail-query-engine.conf

# Setup /etc/contrail/contrail-analytics-api.conf
setcfg /etc/contrail/contrail-analytics-api.conf
setsection "DEFAULTS"
setini host_ip $IPADDRESS
setini http_server_port $ANALYTICS_API_INTROSPECT_PORT
setini rest_api_port $ANALYTICS_API_PORT
setini rest_api_ip $ANALYTICS_API_LISTEN_IP
setini log_local 1
setini log_level $ANALYTICS_API_LOG_LEVEL
setini log_file $ANALYTICS_API_LOG_FILE
setini cassandra_server_list $cassandra_server_list_w_port
setini analytics_data_ttl $ANALYTICS_DATA_TTL
setini analytics_config_audit_ttl $ANALYTICS_CONFIG_AUDIT_TTL
setini analytics_statistics_ttl $ANALYTICS_STATISTICS_TTL
setini analytics_flow_ttl $ANALYTICS_FLOW_TTL

setsection "DISCOVERY"
setini disc_server_ip $DISCOVERY_SERVER
setini disc_server_port $DISCOVERY_PORT

setsection "REDIS"
setini redis_server_port $REDIS_SERVER_PORT
setini redis_query_port $REDIS_SERVER_PORT
setini redis_server_ip $REDIS_SERVER
# END /etc/contrail/contrail-analytics-api.conf setup

# Setup /etc/contrail/contrail-snmp-collector.conf
setcfg /etc/contrail/contrail-snmp-collector.conf
setsection "DEFAULTS"
setini log_local 1
setini log_level $SNMP_COLLECTOR_LOG_LEVEL
setini log_file $SNMP_COLLECTOR_LOG_FILE
setini zookeeper $zk_server_list_w_port

setsection "DISCOVERY"
setini disc_server_ip $DISCOVERY_SERVER
setini disc_server_port $DISCOVERY_PORT
# END /etc/contrail/contrail-snmp-collector.conf

# Setup /etc/contrail/contrail-topology.conf
setcfg /etc/contrail/contrail-topology.conf
setsection "DEFAULTS"
setini log_local 1
setini log_level $TOPOLOGY_LOG_LEVEL
setini log_file $TOPOLOGY_LOG_FILE
setini zookeeper $zk_server_list_w_port

setsection "DISCOVERY"
setini disc_server_ip $DISCOVERY_SERVER
setini disc_server_port $DISCOVERY_PORT
# END /etc/contrail/contrail-topology.conf SETUP

# Setup /etc/contrail/contrail-analytics-nodemgr.conf
setcfg /etc/contrail/contrail-analytics-nodemgr.conf
setsection "DISCOVERY"
setini server $DISCOVERY_SERVER
setini port $DISCOVERY_PORT
# END /etc/contrail/contrail-analytics-nodemgr.conf

setup_keystone_auth_config
setup_vnc_api_lib
