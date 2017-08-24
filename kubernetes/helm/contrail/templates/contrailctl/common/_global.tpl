{{/* ================================================================= */}}
{{/*   Set default varibles needed  by contrail.globalConfig template  */}}
{{/* ================================================================= */}}

{{- define "contrail.setGlobalDefaults" -}}

{{- $_ := required "Controller_nodes should be given as list in .Values.conf.global.controller.nodes" .controller.nodes -}}

{{- if not .analyticsdb.nodes -}}{{- $_ := set .analyticsdb "nodes" .controller.nodes -}}{{- end -}}
{{- if not .analytics.nodes -}}{{- $_ := set .analytics "nodes" .controller.nodes -}}{{- end -}}
{{- if not .config.nodes -}}{{- $_ := set .config "nodes" .controller.nodes -}}{{- end -}}
{{- if not .webui.nodes -}}{{- $_ := set .webui "nodes" .controller.nodes -}}{{- end -}}

{{- if not .controller.virtualIp -}}
{{- $controllerIp := first .controller.nodes -}}
{{- $_ := set .controller "virtualIp" $controllerIp -}}
{{- end -}}
{{- if not .analytics.virtualIp -}}
{{- $analyticsIp := first .analytics.nodes -}}
{{- $_ := set .analytics "virtualIp" $analyticsIp -}}
{{- end -}}
{{- if not .config.virtualIp -}}
{{- $configIp := first .config.nodes -}}
{{- $_ := set .config "virtualIp" $configIp -}}
{{- end -}}

{{- if not .external.rabbitmqServers -}}{{- $_ := set .external "rabbitmqServers" list -}}{{- end -}}
{{- if not .external.controllerZookeeperServers -}}{{- $_ := set .external "controllerZookeeperServers" list -}}{{- end -}}
{{- if not .external.analyticsdbZookeeperServers -}}{{- $_ := set .external "analyticsdbZookeeperServers" list -}}{{- end -}}

{{- end -}}

{{/* =============================================================== */}}
{{/* GLOBAL section of the contrailctl is formed using this template */}}
{{/* =============================================================== */}}


{{- define "contrail.globalConfig" -}}

{{- include "contrail.setGlobalDefaults" . -}}

[GLOBAL]
controller_nodes = {{ .controller.nodes | join "," }}
analytics_nodes = {{ .analytics.nodes | join "," }}
analyticsdb_nodes = {{ .analyticsdb.nodes | join "," }}
config_nodes = {{ .config.nodes | join "," }}
webui_nodes = {{ .webui.nodes | join "," }}

controller_ip = {{ .controller.virtualIp }}
config_ip = {{ .config.virtualIp }}
analytics_ip = {{ .analytics.virtualIp }}

{{ if not .controller.enableControlService }}#{{ end }}enable_control_service = {{ .controller.enableControlService | default "true" }}
{{ if not .webui.enableWebuiService }}#{{ end }}enable_webui_service = {{ .webui.enableWebuiService | default "true" }}
{{ if not .config.enableWebuiService }}#{{ end }}enable_config_service = {{ .webui.enableConfigService | default "true" }}

{{ if not .config.cassandraUser }}#{{ end }}configdb_cassandra_user = {{ .config.cassandraUser | default "" }}
{{ if not .config.cassandraPassword }}#{{ end }}configdb_cassandra_password = {{ .config.cassandraPassword | default "" }}
{{ if not .analyticsdb.cassandraUser }}#{{ end }}analyticsdb_cassandra_user = {{ .analyticsdb.cassandraUser | default "" }}
{{ if not .analyticsdb.cassandraPassword }}#{{ end }}analyticsdb_cassandra_password = {{ .analyticsdb.cassandraPassword | default "" }}

{{/* TODO check if the hosts_entries format works */}}
{{ if not .hostsEntries }}#{{ end }}hosts_entries = {{ .hostsEntries | default "" }}
{{ if not .cloudOrchestrator }}#{{ end }}cloud_orchestrator = {{ .cloudOrchestrator | default "kubernetes" }}

{{ if not .uvePartitionCount }}#{{ end }}uve_partition_count = {{ .uvePartitionCount }}

{{ if not .external.rabbitmqServers }}#{{ end }}external_rabbitmq_servers = {{ .external.rabbitmqServers | join "," }}
{{ if not .external.controllerZookeeperServers }}#{{ end }}external_zookeeper_servers = {{ .external.controllerZookeeperServers | join "," }}
{{ if not .external.analyticsdbZookeeperServers }}#{{ end }}external_analyticsdb_zookeeper_servers = [{{- range .external.analyticsdbZookeeperServers -}}{{ . | quote  }},{{- end }}]

{{ if not .ssl.xmppAuth }}#{{ end }}xmpp_auth_enable = {{ .ssl.xmppAuth | default "false" }}
{{ if not .ssl.xmppDNSAuth }}#{{ end }}xmpp_dns_auth_enable = {{ .ssl.xmppDNSAuth | default "false" }}
{{ if not .ssl.sandesh }}#{{ end }}sandesh_ssl_enable = {{ .ssl.sandesh | default "false" }}
{{ if not .ssl.introspect }}#{{ end }}introspect_ssl_enable = {{ .ssl.introspect | default "false" }}

{{ if not .apiserver.authProtocol }}#{{ end }}apiserver_auth_protocol = {{ .apiserver.authProtocol | default "" }}
{{ if not .apiserver.certfile }}#{{ end }}apiserver_certfile = {{ .apiserver.certfile |  default "" }}
{{ if not .apiserver.keyfile }}#{{ end }}apiserver_keyfile = {{ .apiserver.keyfile | default "" }}
{{ if not .apiserver.cafile }}#{{ end }}apiserver_cafile = {{ .apiserver.cafile | default "" }}
{{ if not .apiserver.insecure }}#{{ end }}apiserver_insecure = {{ .apiserver.insecure | default "" }}

{{ if not .neutron.metadataIP }}#{{ end }}neutron_metadata_ip = {{ .neutron.metadataIP | default "" }}
{{ if not .neutron.metadataPort }}#{{ end }}neutron_metadata_port = {{ .neutron.metadataPort | default "" }}

{{- end -}}
