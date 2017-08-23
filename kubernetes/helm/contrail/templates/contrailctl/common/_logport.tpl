{{/* ============================================================================== */}}
{{/* log and port fields needed by various sections are  formed using this template */}}
{{/* ============================================================================== */}}

{{ define "contrail.logPortConfig" }}

{{ if not .logFile }}#{{ end }}log = {{ .logFile }}
{{ if not .logLevel }}#{{ end }}log_level = {{ .logLevel | default "SYS_NOTICE" }}
{{ if not .introspectPort }}#{{ end }}introspect_port = {{ .introspectPort }}
{{ if not .listenPort }}#{{ end }}listen_port = {{ .listenPort }}

{{- end -}}
