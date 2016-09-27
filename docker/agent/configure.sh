#!/usr/bin/env bash

set -x
source /env.sh

# Build kernel module with dkms - this may not work with redhat/centos, also it need kernel headers installed on the base host
if [ $COMPILE_VROUTER_MODULE == "yes" ]; then
    cp -r /usr/src.orig/vrouter* /usr/src/
    dpkg-reconfigure contrail-vrouter-dkms
fi
depmod -a
modprobe vrouter || fail "Failed loading vrouter kernel module"
lsmod | grep -q vrouter || fail "Failed loading vrouter kernel module"

echo DISCOVERY=$DISCOVERY_SERVER > /etc/contrail/vrouter_nodemgr_param

# Setup /etc/contrail/contrail-vrouter-nodemgr.conf
setcfg /etc/contrail/contrail-vrouter-nodemgr.conf
setsection "DISCOVERY"
setini server $DISCOVERY_SERVER
setini port $DISCOVERY_PORT
# END Setup /etc/contrail/contrail-vrouter-nodemgr.conf

# In case of auto-detecting VROUTER_PHYSICAL_INTERFACE, it is possible that the IP and default route has been
# Transfered to vhost0 during first setup and in intermediate runs, it would need to detect the PHYSICAL_INTERFACE
# from /etc/contrail/agent_param.
if [[ $VROUTER_PHYSICAL_INTERFACE == $VIRTUAL_HOST_INTERFACE ]]; then
    source /etc/contrail/agent_param
    PHYSICAL_INTERFACE=$dev
    PHYSICAL_INTERFACE_MAC=$physical_interface_mac
else
    PHYSICAL_INTERFACE=$VROUTER_PHYSICAL_INTERFACE
    PHYSICAL_INTERFACE_MAC=$VROUTER_PHYSICAL_INTERFACE_MAC
fi

# Setup /etc/contrail/contrail-vrouter-agent.conf
setcfg /etc/contrail/contrail-vrouter-agent.conf
setsection "VIRTUAL-HOST-INTERFACE"
setini name $VIRTUAL_HOST_INTERFACE
setini ip $VIRTUAL_HOST_INTERFACE_IP_WITH_MASK
setini gateway $NODE_GATEWAY
setini physical_interface $PHYSICAL_INTERFACE

setsection "DEFAULTS"
setini platform default # No work on dpdk is done, so hardcoding here
setini log_file $VROUTER_AGENT_LOG_FILE
setini log_level $VROUTER_AGENT_LOG_LEVEL
setini log_local 1
setini physical_interface_mac $PHYSICAL_INTERFACE_MAC

setsection DISCOVERY
setini server $DISCOVERY_SERVER
setini max_control_nodes 3

setsection NETWORKS
setini control_network_ip $VIRTUAL_HOST_INTERFACE_IP
# END Setup /etc/contrail/contrail-vrouter-agent.conf

cat << EOF > /etc/contrail/agent_param
LOG=/var/log/contrail.log
CONFIG=/etc/contrail/contrail-vrouter-agent.conf
prog=/usr/bin/contrail-vrouter-agent
kmod=vrouter
pname=contrail-vrouter-agent
LIBDIR=/usr/lib64
DEVICE=vhost0
dev=$PHYSICAL_INTERFACE
physical_interface_mac=$PHYSICAL_INTERFACE_MAC
vgw_subnet_ip=
vgw_int=
LOGFILE=--log-file=/var/log/contrail/vrouter.log
EOF

setup_keystone_auth_config
setup_vnc_api_lib

source /opt/contrail/bin/vrouter-functions.sh
insert_vrouter
if [[ $VROUTER_PHYSICAL_INTERFACE != $VIRTUAL_HOST_INTERFACE ]]; then
    ip address delete $VIRTUAL_HOST_INTERFACE_IP_WITH_MASK dev $PHYSICAL_INTERFACE
    ip address add $VIRTUAL_HOST_INTERFACE_IP_WITH_MASK dev $VIRTUAL_HOST_INTERFACE
    ip link set dev $VIRTUAL_HOST_INTERFACE up
    if [[ ${VIRTUAL_HOST_INTERFACE_IP_WITH_MASK#*/} -eq 32 ]]; then
        ip route add unicast $NODE_GATEWAY dev $VIRTUAL_HOST_INTERFACE scope link
    fi
    ip route add default via $NODE_GATEWAY dev $VIRTUAL_HOST_INTERFACE
fi
