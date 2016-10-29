# This file contain parameter maps between container specific configuration entries and ansible variables
# This will be used to write/update ansible variables to sync with per container configuration
#
# Here below explained the default parameter mapping behavior:
# 1. Parameter in DEFAULT section is mapped to same name in variable definition i.e a parameter controller_list
#   in [GLOBAL] section will be mapped to same parameter in ansible variable definition file under group_vars.
# 2. Parameters in Other sections will be appended with the lower cased secion names. i.e, a parameter "server_port" in
#    [IFMAP] section is translated to ifmap_server_port for ansible variable definition
#
# Default maps doesnt need to be added here, all non-default map must be specified here.

ANALYTICS_PARAM_MAP = dict(
    GLOBAL=dict(
        analyticsdb_list="analyticsdb_list",
        controller_list="controller_list",
        controller_ip="controller_ip",
        uve_partition_count="analytics_uve_partition_count",
        analytics_data_ttl="analytics_data_ttl",
        analytics_flow_ttl="analytics_flow_ttl",
        analytics_statistics_ttl="analytics_statistics_ttl",
        analytics_config_audit_ttl="analytics_config_audit_ttl",
        aaa_mode="analytics_aaa_mode",
        sandesh_send_rate_limit="sandesh_send_rate_limit"
    )
)

CONTROLLER_PARAM_MAP = dict(
    GLOBAL={},
    IFMAP={},
    CASSANDRA={},
    ZK={},
    RABBITMQ={},
    REDIS={},
    CONFIG=dict(
        api_listen_port='api_listen_port',
        api_listen_address='api_listen_address',
        api_log_level='api_log_level'
    ),
    CONTROL={},
    WEBUI={},
    SCHEMA={},
)

ANALYTICSDB_PARAM_MAP = dict(
    GLOBAL=dict(
        controller_list="controller_list",
        controller_ip="controller_ip"
    ),
)
ANALYTICS_PARAM_MAP = {}
