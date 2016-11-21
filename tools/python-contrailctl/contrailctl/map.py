# This file contain parameter maps between container specific configuration
# entries and ansible variables. This will be used to write/update ansible
# variables to sync with per container configuration
#
# Here below explained the default parameter mapping behavior:
# 1. Parameter in DEFAULT section is mapped to same name in variable definition
#    i.e a parameter controller_list  in [GLOBAL] section will be mapped to
#    same parameter in ansible variable definition file under group_vars.
# 2. Parameters in Other sections will be appended with the lower cased secion
#    names. i.e, a parameter "server_port" in [IFMAP] section is translated to
#    ifmap_server_port for ansible variable definition
#
# Default maps doesnt need to be added here, all non-default map must be
# specified here.

LB_PARAM_MAP = dict(
    GLOBAL=dict(
        controller_list="controller_list",
    ),
    HAPROXY=dict(
        user="haproxy_auth_user",
        password="haproxy_auth_password",
    )
)

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
    GLOBAL=dict(
        controller_list="controller_list",
        controller_ip="controller_ip"
    ),
    CONTROL=dict(
        bgp_port="bgp_port",
        xmpp_server_port="xmpp_server_port",
        sandesh_send_rate_limit="sandesh_send_rate_limit"
    ),
    DNS=dict(
        named_config_file="named_config_file",
        named_config_directory="named_config_directory",
        named_log_file="named_log_file",
        rndc_config_file="rndc_config_file",
        rndc_secret="rndc_secret",
        dns_server_port="dns_server_port",
    ),
    API=dict(
        list_optimization_enabled="list_optimization_enabled",
        multi_tenancy="multi_tenancy",
    )
)

ANALYTICSDB_PARAM_MAP = dict(
    GLOBAL=dict(
        analyticsdb_list="analyticsdb_list",
        controller_list="controller_list",
        controller_ip="controller_ip"
    ),
)
