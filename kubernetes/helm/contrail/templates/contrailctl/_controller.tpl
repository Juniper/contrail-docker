{{/* ======================================================================= */}}
{{/* Controller container specific sections are formed using this template   */}}
{{/* ======================================================================= */}}

{{- define "contrail.controllerConfig" -}}

{{/* ==================== CONTROLLER SECTION ======================= */}}
[CONTROLLER]
{{ if not .controller.encapPriority }}#{{ end }}encap_priority = {{ .controller.encapPriority | default "MPLSoUDP,MPLSoGRE,VXLAN" }}

{{ if not .controller.externalRoutersList }}#{{ end }}external_routers_list = {{ .controller.externalRoutersList }}

{{ if not .controller.bgpAsn }}#{{ end }}bgp_asn = {{ .controller.bgpAsn | default 64512 }}

{{ if not .controller.flowExportRate }}#{{ end }}flow_export_rate = {{ .controller.flowExportRate }}


{{/* ==================== CONTROL SECTION ======================= */}}
[CONTROL]
{{ include "contrail.logPortConfig" .control.logPortInfo }}

{{ if not .control.bgpPort }}#{{ end }}bgp_port = {{ .control.bgpPort | default 179 }}

{{ if not .control.xmpp_server_port }}#{{ end }}xmpp_server_port = {{ .control.xmpp_server_port | default 5269 }}

{{/* ==================== API SECTION ======================= */}}
[API]
{{ include "contrail.logPortConfig" .contrailAPI.logPortInfo }}

{{ if not .contrailAPI.listenAddress }}#{{ end }}listen_address = {{ .contrailAPI.listenAddress | default "0.0.0.0" }}

{{ if not .contrailAPI.listOptimizationEnabled }}#{{ end }}list_optimization_enabled = {{ .contrailAPI.listOptimizationEnabled | default "true" }}

{{ if not .contrailAPI.cloudAdminRole }}#{{ end }}cloud_admin_role = {{ .contrailAPI.cloudAdminRole | default "admin" }}

{{ if not .contrailAPI.globalReadOnlyRole }}#{{ end }}global_read_only_role = {{ .contrailAPI.globalReadOnlyRole  }}

{{ if not .contrailAPI.aaaMode }}#{{ end }}aaa_mode = {{ .contrailAPI.aaaMode | default "no-auth" }}

{{/* ==================== SCHEMA SECTION ======================= */}}
[SCHEMA]
{{ include "contrail.logPortConfig" .schema.logPortInfo }}


{{/* ==================== SVC_MONITOR SECTION ======================= */}}
[SVC_MONITOR]
{{ include "contrail.logPortConfig" .svcMonitor.logPortInfo }}

{{/* ==================== DEVICE_MANAGER SECTION ======================= */}}
[DEVICE_MANAGER]
{{ include "contrail.logPortConfig" .deviceManager.logPortInfo }}

{{/* ==================== DNS SECTION ======================= */}}
[DNS]

{{ include "contrail.logPortConfig" .dns.logPortInfo }}

{{ if not .dns.namedLogFile }}#{{ end }}named_log_file = {{ .dns.namedLogFile | default "/var/log/contrail/contrail-named.log" | quote }}

{{ if not .dns.dnsPort }}#{{ end }}dns_server_port = {{ int .dns.dnsPort | default 53 }}

{{/* ==================== RABBITMQ SECTION ======================= */}}
{{ include "contrail.rabbitmqConfig" . }}

{{/* ==================== WEBUI SECTION ======================= */}}
[WEBUI]
{{ if not .webui.httpListenPort }}#{{ end }}http_listen_port = {{ .webui.httpListenPort | default 8080 }} 

{{ if not .webui.httpsListenPort }}#{{ end }}https_listen_port = {{ .webui.httpsListenPort | default 8143  }} 

{{ if not .webui.storageEnable }}#{{ end }}webui_storage_enable = {{ .webui.storageEnable | default "false" }}

{{ if not .webui.enableUnderlay }}#{{ end }}enable_underlay = {{ .webui.enableUnderlay | default "false"  }}

{{ if not .webui.enableMX }}#{{ end }}enable_mx = {{ .webui.enableMX | default "false"  }}

{{ if not .webui.enableUdd }}#{{ end }}enable_udd = {{ .webui.enableUdd | default "false"  }}

{{ if not .webui.serviceEPFromConfig }}#{{ end }}service_endpoint_from_config = {{ .webui.serviceEPFromConfig | default "false" }}

{{ if not .webui.serverOptionsKeyFile }}#{{ end }}server_options_key_file = {{ .webui.serverOptionsKeyFile }}

{{ if not .webui.serverOptionsCertFile }}#{{ end }}server_options_cert_file = {{ .webui.serverOptionsCertFile  }}

{{/* ==================== ANALYTICS_API SECTION ======================= */}}
[ANALYTICS_API]

{{ if not .analyticsAPI.aaaMode }}#{{ end }}aaa_mode = {{ .analyticsAPI.aaaMode | default "no-auth" }}

{{/* ==================== CASSADRA SECTION ======================= */}}
{{ include "contrail.cassandraConfig" .configdbCassandra }}

{{- end -}}
