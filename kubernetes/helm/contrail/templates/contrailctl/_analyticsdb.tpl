{{/* ====================================================================== */}}
{{/* Analyticsdb container specific sections are formed using this template */}}
{{/* ====================================================================== */}}

{{- define "contrail.analyticsdbConfig" -}}

{{/* ==================== CASSADRA SECTION ======================= */}}

{{- include "contrail.cassandraConfig" .analyticsdbCassandra -}}

{{- end -}}
