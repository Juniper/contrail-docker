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

function webui_config() {
    # NOTE: This function should be called with all quotes escaped. It will not add any quotes for you.
    # For example, if you want my_key = 'value1' in your config.global.js file, you would need to escape
    # Quotes in 'value1' so that it will be like this "'value1'"
    key=$1
    value="$2"
    sed -i "/^$key *=/{h;s/=.*/= $value/};\${x;/^\$/{s//$key = $value/;H};x}" /etc/contrail/config.global.js
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

# Try to resolve the name if not resolved, use default IP address provided.
# Also check the port connectivity, and if connected, send right ip address
# If not connected, return 1
#
# Along with retry(), it can wait till the service is up on an IP and return
# right IP address where the service is listen
function get_right_ip() {
    name=$1
    IP_DEFAULT=$2
    PORT=$3
    # Valid protocols are http, https, tcp
    PROTOCOL=${4:-"http"}
    name_resolve_ip=$(ipof $name)
    if [[ $name_resolve_ip ]]; then
        IP=$name_resolve_ip
    else
        IP=$IP_DEFAULT
    fi
    if [[ $PROTOCOL == "http" || $PROTOCOL == "https" ]]; then
        url=http://${IP}:${PORT}
        response=$(curl -s -o /dev/null -I -w "%{http_code}" $url || true)
        if [[ $response -ge 500 || $response -eq 0 ]]; then
            response=1
        else
            response=0
        fi
    elif [[ $PROTOCOL == "tcp" ]]; then
        timeout  10 nc -z $IP $PORT
        response=$?
    fi

    if [[ $response -eq 0 ]]; then
        echo $IP
        return 0
    else
        return 1
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
