{{/* =============================================================== */}}
{{/* GLOBAL section of the contrailctl is formed using this template */}}
{{/* =============================================================== */}}
{{- define "globalConfig" -}}
[GLOBAL]
{{- if not .global -}}{{- $_ := set . "global" dict -}}{{- end -}}
{{- $controller_nodes := .global.controller_nodes -}}
{{- $analyticsdb_nodes := .global.analyticsdb_nodes | default .global.controller_nodes -}}
{{- $analytics_nodes := .global.analytics_nodes | default .global.controller_nodes }}
controller_nodes = {{ $len_controller_nodes := len $controller_nodes -}}{{ if gt $len_controller_nodes 1 -}}{{ $controller_nodes | join "," }}{{ else -}} {{ first $controller_nodes }}{{ end }}
analyticsdb_nodes = {{ $len_analyticsdb_nodes := len $analyticsdb_nodes -}}{{ if gt $len_analyticsdb_nodes 1 -}}{{ $analyticsdb_nodes | join "," }}{{ else -}}{{ first $analyticsdb_nodes }}{{ end }}
analytics_nodes = {{ $len_analytics_nodes := len $analytics_nodes -}}{{ if gt $len_analytics_nodes 1 -}}{{ $analytics_nodes | join "," }}{{ else -}}{{ first $analytics_nodes }}{{ end }}
config_nodes = {{ $len_controller_nodes := len $controller_nodes -}}{{ if gt $len_controller_nodes 1 -}}{{ $controller_nodes | join "," }}{{ else -}}{{ first $controller_nodes }}{{ end }}
controller_ip = {{ first $controller_nodes }}
config_ip = {{ first $controller_nodes }}
analytics_ip = {{ first $analytics_nodes }}
enable_webui_service = {{ .global.enable_webui_service | default "True" }}
enable_config_service = {{ .global.enable_config_service | default "True" }}
cloud_orchestrator = {{ .global.cloud_orchestrator | default "kubernetes" }}
introspect_ssl_enable = {{ .global.introspect_ssl_enable | default  "False" }}
enable_control_service = {{ .global.enable_control_service | default "True" }}
sandesh_ssl_enable = {{ .global.sandesh_ssl_enable | default "False" }}
{{- end -}}
