#!/usr/bin/env bash

source /env.sh

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
if [[ $KAFKA_ENABLED ]]; then
    setini kafka_broker_list $kafka_broker_list_w_port
fi
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
setini syslog_port $ANALYTICS_SYSLOG_PORT

setsection "COLLECTOR"
setini port $COLLECTOR_PORT

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
