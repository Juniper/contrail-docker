#!/usr/bin/env bash
# Copied from contrail-provisioning and modified as required

# HA_NODE_IP_LIST variable is send to the container so is available as environment variable

# This script will check if it can connect to any of the ha nodes, and fail if all of them failed.

HA_NODE_IP_LIST=${HA_NODE_IP_LIST}
node_ips=$(echo $HA_NODE_IP_LIST | sed 's/,/ /g')
MYIPS=$(ip a s|sed -ne '/127.0.0.1/!{s/^[ \t]*inet[ \t]*\([0-9.]\+\)\/.*$/\1/p}')

ret=0

for myip in $MYIPS; do
    for ip in $node_ips; do
        if [[ $mine != $ip ]]; then
            packet_loss=$(ping -c 1 -w 1 -W 1 -n ${ip} | grep packet | awk '{print $6}' | cut -c1)
            if [[ $packet_loss == 0 ]]; then
                exit 0
            fi
        fi
    done
done

exit 1
