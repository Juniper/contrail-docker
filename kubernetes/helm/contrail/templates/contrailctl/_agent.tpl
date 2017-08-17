{{/* =============================================================== */}}
{{/* AGENT section of the contrailctl is formed using this template */}}
{{/* =============================================================== */}}
{{- define "agentConfig" -}}
[AGENT]
{{- if not .agent -}}{{- $_ := set . "agent" dict -}}{{- end }}
{{- if not .hostOs -}}{{- $_ := set . "hostOs" "ubuntu" -}}{{- end }}
{{- if eq .hostOs "centos7" -}}{{- $_ := set .agent "compile_vrouter_module" "False" -}}{{- end }}
compile_vrouter_module = {{ .agent.compile_vrouter_module | default "True" }}
vrouter_physical_interface = {{ .agent.vrouter_physical_interface | default "eth0" }}
{{- end -}}
