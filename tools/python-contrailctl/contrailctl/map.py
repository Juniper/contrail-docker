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
    HAPROXY=dict(
        user="haproxy_auth_user",
        password="haproxy_auth_password",
    ),
    HAPROXY_TORAGENT=dict(
        haproxy_toragent_config="haproxy_toragent_config"
    )
)

CONTROLLER_PARAM_MAP = dict(
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
    ),
    WEBUI=dict(
        webui_storage_enable="webui_storage_enable",
        nova_api_ip="nova_api_ip",
        glance_api_ip="glance_api_ip",
        network_manager_ip='network_manager_ip',
    )
)

ANALYTICS_PARAM_MAP = {}
ANALYTICSDB_PARAM_MAP = {}
AGENT_PARAM_MAP = {}
KUBEMANAGER_PARAM_MAP = {}
KUBERNETESAGENT_PARAM_MAP = {}
MESOSMANAGER_PARAM_MAP = {}
CEPHCONTROLLER_PARAM_MAP = dict(
    CEPH_CONTROLLER=dict(
        cluster_fsid="cluster_fsid",
        ceph_monip_list="ceph_monip_list",
        ceph_monname_list="ceph_monname_list",
        mon_key="mon_key",
        osd_key="osd_key",
        adm_key="adm_key",
        ceph_rest_api_port="ceph_rest_api_port",
        enable_stats_daemon="enable_stats_daemon",
    )
)
CONTRAIL_ISSU_MAP = {}
