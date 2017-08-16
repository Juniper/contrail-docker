{{/* ============================================================== */}}
{{/* WEBUI section of the contrailctl is formed using this template */}}
{{/* ============================================================== */}}
{{- define "webuiConfig" -}}
[WEBUI]
{{- if not .webui -}}{{- $_ := set . "webui" dict -}}{{- end }}
http_listen_port = {{ .webui.http_listen_port | default 8080 }} 
https_listen_port = {{ .webui.https_listen_port | default 8143  }} 
webui_storage_enable = {{ .webui.webui_storage_enable | default "False" }}
{{- end -}}
