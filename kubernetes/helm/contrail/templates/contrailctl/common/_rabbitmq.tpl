{{/* =============================================================== */}}
{{/* RABBITMQ section of the contrailctl is formed using this template */}}
{{/* =============================================================== */}}

{{- define "contrail.rabbitmqConfig" -}}

[RABBITMQ]

{{ if not .rabbitmq.user }}#{{ end }}user = {{ .rabbitmq.user | default "guest" }}
{{ if not .rabbitmq.password }}#{{ end }}password = {{ .rabbitmq.password | default  "guest" }}
{{ if not .rabbitmq.vhost }}#{{ end }}vhost = {{ .rabbitmq.vhost | default "/" }}
{{ if not .rabbitmq.owner }}#{{ end }}owner = {{ .rabbitmq.owner  }}
{{ if not .rabbitmq.group }}#{{ end }}group = {{ .rabbitmq.group  }}


{{- end -}}
