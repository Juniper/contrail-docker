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

CONTROLLER_PARAM_MAP = dict(
    GLOBAL={},
    IFMAP={},
    CASSANDRA={},
    ZK={},
    RABBITMQ={},
    REDIS={},
    CONFIG={},
    CONTROL={},
    WEBUI={},
    SCHEMA={},
    SECURITY={},
    DB={},
    DISCOVERY={}
)
