#!/usr/bin/env bash

function fail() {
    echo "$@"
    exit 1

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