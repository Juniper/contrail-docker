{{/* ====================================================================== */}}
{{/* Analytics container specific sections are formed using this template   */}}
{{/* ====================================================================== */}}

{{- define "contrail.analyticsConfig" -}}

{{/* ================== ANALYTICS_API section ==================== */}}
[ANALYTICS_API]
{{ include "contrail.logPortConfig" .analyticsAPI.logPortInfo }}

{{ if not .analyticsAPI.aaaMode }}#{{ end }}aaa_mode = {{  .analyticsAPI.aaaMode | default "no-auth" }}

{{/* ================== ANALYTICS_COLLECTOR section ==================== */}}
[ANALYTICS_COLLECTOR]
{{ include "contrail.logPortConfig" .analyticsCollector.logPortInfo }}

{{ if not .analyticsCollector.syslogPort }}#{{ end }}syslog_port = {{ .analyticsCollector.syslogPort }}

{{ if not .analyticsCollector.analyticsFlowTTL }}#{{ end }}analytics_flow_ttl = {{ .analyticsCollector.analyticsFlowTTL | default 48 }}

{{ if not .analyticsCollector.analyticsStatisticsTTL }}#{{ end }}analytics_statistics_ttl = {{ .analyticsCollector.analyticsStatisticsTTL | default 2160 }}

{{ if not .analyticsCollector.analyticsConfigAuditTTL }}#{{ end }}analytics_config_audit_ttl = {{ .analyticsCollector.analyticsConfigAuditTTL | default 24 }}

{{ if not .analyticsCollector.analyticsDataTTL }}#{{ end }}analytics_data_ttl = {{ .analyticsCollector.analyticsDataTTL | default }}

{{/* ================== ALARM_GEN section ==================== */}}
[ALARM_GEN]
{{ include "contrail.logPortConfig" .alarmGen.logPortInfo }}
{{/* ================== QUERY_ENGINE section ==================== */}}

[QUERY_ENGINE]
{{ include "contrail.logPortConfig" .queryEngine.logPortInfo }}

{{/* ================== TOPOLOGY section ==================== */}}
[TOPOLOGY]
{{ include "contrail.logPortConfig" .topology.logPortInfo }}

{{/* ================== SNMP_COLLECTOR  section ==================== */}}
[SNMP_COLLECTOR]
{{ include "contrail.logPortConfig" .snmpCollector.logPortInfo }}

{{ if not .snmpCollector.scanFreq }}#{{ end }}scan_frequency = {{ .snmpCollector.scanFreq | default 600 }}

{{ if not .snmpCollector.fastScanFreq }}#{{ end }}fast_scan_frequency = {{ .snmpCollector.fastScanFreq | default 60 }}

{{/* ==================== RABBITMQ SECTION ======================= */}}
{{ include "contrail.rabbitmqConfig" . }}

{{- end -}}
