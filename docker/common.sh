#!/usr/bin/env bash

set -a # Export all variables below this statement
export PATH=$PATH:/opt/contrail/bin:/usr/share/contrail-utils/

primary_if=$(ip route list | awk  '/default/ {if (NR==1); print $NF}')
primary_ip=$(ifconfig $primary_if | awk '/inet.addr:/ {print $2}' | cut -f2 -d:)
KEYSTONE_SERVER=${KEYSTONE_SERVER:-$primary_ip}
KEYSTONE_AUTH_PROTOCOL=${KEYSTONE_AUTH_PROTOCOL:-"http"}
KEYSTONE_AUTH_PORT=${KEYSTONE_AUTH_PORT:-35357}
KEYSTONE_INSECURE=${KEYSTONE_INSECURE:-False}

function fail() {
    echo "$@"
    exit 1

}

function ipof() {
    name=$1
    getent hosts ${name} | awk '{print $1}'
}

function setini() {
    param=$1; shift
    value=$@
    section=$SECTION
    config_file=$CONFIG_FILE
    crudini --set $config_file $section $param "$value"
}

function setcfg() {
    CONFIG_FILE=$1
    touch $CONFIG_FILE
}

function setsection() {
    SECTION=$1
}

function setup_keystone_auth_config() {
    # Setup contrail-keystone-auth.conf
    setcfg "/etc/contrail/contrail-keystone-auth.conf"
    setsection "KEYSTONE"
    setini auth_host $KEYSTONE_SERVER
    setini auth_protocol $KEYSTONE_AUTH_PROTOCOL
    setini auth_port $KEYSTONE_AUTH_PORT
    setini admin_user $KEYSTONE_ADMIN_USER
    setini admin_password $KEYSTONE_ADMIN_PASSWORD
    setini admin_tenant_name $KEYSTONE_ADMIN_TENANT
    setini insecure $KEYSTONE_INSECURE
    setini memcache_servers $KEYSTONE_MEMCACHE_SERVERS
    # END contrail-keystone-auth.conf
}

function setup_vnc_api_lib() {
    # Setup vnc_api_lib.ini
    setcfg "/etc/contrail/vnc_api_lib.ini"
    setsection "global"
    setini WEB_SERVER "127.0.0.1"
    setini WEB_PORT 8082
    setini BASE_URL "/"

    setsection "auth"
    setini AUTHN_TYPE "keystone"
    setini AUTHN_PROTOCOL $KEYSTONE_AUTH_PROTOCOL
    setini AUTHN_SERVER $KEYSTONE_SERVER
    setini AUTHN_PORT $KEYSTONE_AUTH_PORT
    setini AUTHN_URL "/v2.0/tokens"
    setini insecure $KEYSTONE_INSECURE
    # END vnc_api_lib.ini setup
}

function check_port() {
    ip=$1
    port=$2
    </dev/tcp/${ip}/${port}
}

function wait_for_service_port() {
    ip=$1
    port=$2
    while  ! check_port $ip $port; do
        sleep 5
    done
}

function wait_for_url() {
    url=$1
    response=$(curl -s -o /dev/null -I -w "%{http_code}" $url || true)
    while [[ $response -ge 500 || $response -eq 0 ]]; do
        sleep 5
        response=$(curl -s -o /dev/null -I -w "%{http_code}" $url || true)
    done
}

function check_url() {
    name=$1
    IP_DEFAULT=$2
    PORT=${3:-8082}
    name_resolve_ip=$(ipof $name)
    if [[ $name_resolve_ip ]]; then
        IP=$name_resolve_ip
    else
        IP=$IP_DEFAULT
    fi
    url=http://${IP}:${PORT}
    response=$(curl -s -o /dev/null -I -w "%{http_code}" $url || true)
    if [[ $response -ge 500 || $response -eq 0 ]]; then
      return 1
    else
        echo $IP
        return 0
    fi
}

##
# Function to retry other functions or commands
# variables: $timeout , $wait
# Example: retry do_something -f arg1 -d arg2 arg3
##
function retry() {
    timeout=${timeout:-300}
    wait=${wait:-5}
    cmd=$1; shift
    args=$*
    rv=1
    duration=0
    while [[ $rv -ne 0 ]]; do
        $cmd $args
        rv=$?
        sleep $wait
        duration=$(($duration+$wait))
        if [[ $duration -ge $timeout ]]; then
            echo "Timeout occurred"
            return 1
        fi
    done
}

##
# Function to connect to discovery service and get the ipaddress:port list for provided service type
# Run it with discovory services.json url as first argument and service_type as second argument
# e.g get_service_connect_details http://10.0.0.10:5998/services.json ApiServer
##
function get_service_connect_details() {
    discovery_services_json_url=$1
    service_type=$2
    ip_port=`curl -s ${discovery_services_json_url} | jq ".services[] | \
        if .service_type == \"${service_type}\" then .info[\"ip-address\"] + \":\" + .info.port else empty end " |\
        sed 's/"//g'`
    rv=$?
    echo "${ip_port}" # send space separated list of ip:port values for provided service type
}

function sort_ips() {
    # Input is a list of ip addresses separated by space or comma
    ip_list=$1
    echo $ip_list | sed -r 's/[\s,]+/\n/g' | sort -V
}

function index_of_ip() {
    # Input is a list of ip addresses separated by space or comma
    # search is an ip address of which the index is returned (starts from 1)
    ip_list=$1
    search=$2
    echo "$(sort_ips $ip_list)" | grep -nP "^${search}\b" | cut -f1 -d:
}
