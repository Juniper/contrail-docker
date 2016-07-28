#!/usr/bin/env bash

source /env.sh

# Setup contrail-control.conf
setcfg "/etc/contrail/contrail-control.conf"
setsection DEFAULT
setini hostip $IPADDRESS
setini hostname $HOSTNAME
setini log_file $CONTROL_LOG_FILE
setini log_level $CONTROL_LOG_LEVEL
setini log_local 1

setsection DISCOVERY
setini server $DISCOVERY_SERVER

setsection IFMAP
setini user $CONTROL_IFMAP_USER
setini password $CONTROL_IFMAP_PASSWORD
setini certs_store $CONTROL_CERTS_STORE

# End contrail-control.conf setup

# Setup contrail-dns.conf
setcfg "/etc/contrail/contrail-dns.conf"
setsection "DEFAULT"
setini hostip $IPADDRESS
setini hostname $HOSTNAME
setini log_file $DNS_LOG_FILE
setini log_level $DNS_LOG_LEVEL
setini log_local 1

setsection DISCOVERY
setini server $DISCOVERY_SERVER

setsection "IFMAP"
setini user $DNS_IFMAP_USER
setini password $DNS_IFMAP_PASSWORD
setini certs_store $CONTROL_CERTS_STORE
# END contrail-dns.conf


# Setup contrail-control-nodemgr.conf
setcfg "/etc/contrail/contrail-control-nodemgr.conf"
setsection "DISCOVERY"
setini server $DISCOVERY_SERVER
setini port $DISCOVERY_PORT
# END contrail-control-nodemgr.conf

setup_keystone_auth_config
setup_vnc_api_lib

# FIXME - would need to create secret rather than accept it as variable. Also may be it need better regex
#   to handle multiple space etc
for file in /etc/contrail/dns/contrail-rndc.conf /etc/contrail/dns/contrail-named.conf; do
    sed -i 's/secret \"secret123\";/secret \"${DNS_RNDC_KEY}\";/g' $file
done
