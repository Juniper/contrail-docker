#!/usr/bin/env bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
test -x $DAEMON || exit 0


STATS_PORT=${STATS_PORT:-5937}
NEUTRON_SERVER_LIST=${NEUTRON_SERVER_LIST}
CONTRAIL_API_SERVER_LIST=${CONTRAIL_API_SERVER_LIST}
DISCOVERY_SERVER_LIST=${DISCOVERY_SERVER_LIST}

# Keepalived config entries
if [[ ! $IPADDRESS ]]; then
    echo "Variable \"\$IPADDRESS\" must be provided"
    exit 1
fi

set -a # Export all variables below this statement
# VIP should be in the form <ip address>/<mask bits>. E.g 192.168.0.100/24
HA_ENABLED=${HA_ENABLED}
INTERNAL_VIP=${INTERNAL_VIP}
EXTERNAL_VIP=${EXTERNAL_VIP}
INTERNAL_DEVICE_DETECTED=$(ip a show | grep -B3 "inet ${IPADDRESS}" | awk '/^[0-9]/ {gsub(":", "", $2); print $2}')
INTERNAL_DEVICE=${INTERNAL_DEVICE:-$INTERNAL_DEVICE_DETECTED}
EXTERNAL_DEVICE=${EXTERNAL_DEVICE}
HA_NODE_IP_LIST=${HA_NODE_IP_LIST} # should be comma seperated list of ips
EXTERNAL_VIRTUAL_ROUTER_ID=${EXTERNAL_VIRTUAL_ROUTER_ID:-101}
INTERNAL_VIRTUAL_ROUTER_ID=${INTERNAL_VIRTUAL_ROUTER_ID:-100}
NODE_INDEX=${NODE_INDEX}
RABBITMQ_SERVER_LIST=${RABBITMQ_SERVER_LIST}
## Setup haproxy
# Include supervisor defaults if available
if [ -f /etc/default/haproxy ] ; then
	. /etc/default/haproxy
fi


pyj2.py -t /haproxy.cfg.j2 -o /etc/haproxy/haproxy.cfg -v neutron_server_list=$NEUTRON_SERVER_LIST \
    contrail_api_server_list=${CONTRAIL_API_SERVER_LIST} \
    discovery_server_list=${DISCOVERY_SERVER_LIST}
mkdir -p /var/run/haproxy /var/log/haproxy
chown -R haproxy.haproxy /var/run/haproxy /var/log/haproxy

## END Setup haproxy

if [[ $HA_ENABLED ]]; then
    ## Setup keepalived
    num_nodes=$(($(echo $HA_NODE_IP_LIST| grep -o ',' | wc -l)+1))

    state='BACKUP'
    delay=1
    preempt_delay=1
    timeout=1
    rise=1
    fall=1
    garp_master_repeat=3
    garp_master_refresh=1
    ctrl_data_timeout=3
    ctrl_data_rise=1
    ctrl_data_fall=1
    internal_vip_ip=${INTERNAL_VIP%\/*}}
    external_vip_ip=${EXTERNAL_VIP%\/*}}

    if [[ ( $NODE_INDEX == 1 ) || ($num_nodes > 2 && $NODE_INDEX == 2) ]]; then
        state='MASTER'
        delay=5
        preempt_delay=7
        timeout=3
        rise=2
        fall=2
    fi

    priority=$((100-$NODE_INDEX))

    ## Write the config file
    # First time is to rewrite the file
    if [[ $INTERNAL_VIP ]]; then
        vip=$INTERNAL_VIP
        device=$INTERNAL_DEVICE
        vip_ip=$internal_vip_ip
        virtual_router_id=$INTERNAL_VIRTUAL_ROUTER_ID
        vip_name="INTERNAL"
        pyj2.py -t /keepalived.conf.j2 -o /etc/keepalived/keepalived.conf
    fi

    # Write for external_vip
    if [[ $EXTERNAL_VIP ]]; then
        vip=$EXTERNAL_VIP
        device=$EXTERNAL_DEVICE
        vip_ip=$external_vip_ip
        virtual_router_id=$EXTERNAL_VIRTUAL_ROUTER_ID
        vip_name="EXTERNAL"
        if [[ $INTERNAL_VIP ]]; then
            # Already written the config, so append
            pyj2.py -t /keepalived.conf.j2 -o /etc/keepalived/keepalived.conf -a
        else
            pyj2.py -t /keepalived.conf.j2 -o /etc/keepalived/keepalived.conf
        fi
    fi

    DAEMON=/usr/bin/supervisord
    test -x $DAEMON || exit 0
    LOG=/var/log/supervisor.log
    SOCKETFILE=/var/run/supervisor.sock
    # Include supervisor defaults if available
    if [ -f /etc/default/supervisord} ] ; then
        . /etc/default/supervisord
    fi
    DAEMON_OPTS="-n -c /etc/supervisor/supervisord.conf $DAEMON_OPTS"

    function cleanup() {
        supervisorctl -s unix://${SOCKETFILE} stop all
        supervisorctl -s unix://${SOCKETFILE} shutdown
        rm -f $SOCKETFILE
    }

    trap cleanup SIGHUP SIGINT SIGTERM

else
    rm -f /etc/supervisor/conf.d/keepalived.conf
    DAEMON=/usr/sbin/haproxy
    DAEMON_OPTS="-f /etc/haproxy/haproxy.cfg -db"
    LOG=/var/log/haproxy/haproxy-stdout.log
fi

## END setup keepalived


$DAEMON $DAEMON_OPTS 2>&1 | tee -a $LOG &
child=$!
wait "$child"
