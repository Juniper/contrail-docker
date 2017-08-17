{{/* =================================================================== */}}
{{/* KUBERNETES section of the contrailctl is formed using this template */}}
{{/* =================================================================== */}}
{{- define "kubernetesConfig" -}}
[KUBERNETES]
{{- if not .kubernetes -}}{{- $_ := set . "kubernetes" dict -}}{{- end }}
{{- $kubernetes_api_server_default := first .global.controller_nodes }}
api_server = {{ .kubernetes.kubernetes_api_server | default $kubernetes_api_server_default }}
cluster_name = {{ .kubernetes.cluster_name | default "default-cluster" }}
cluster_network = {}
pod_subnets = {{ .kubernetes.kubernetes_pod_subnets | default "10.32.0.0/12" }}
service_subnets = {{ .kubernetes.kubernetes_service_subnets | default "10.96.0.0/12" }}
cluster_project = {{ if not .kubernetes.kubernetes_cluster_project -}}{'domain': 'default-domain', 'project': 'default'}{{ else -}}{{ .kubernetes.kubernetes_cluster_project }}{{- end }}
token = {{ .kubernetes.kubernetes_access_token | default "" }}
[KUBERNETES_VNC]
public_fip_pool = {{- if not .kubernetes.kubernetes_public_fip_pool -}}{}{{- else -}}{{ .kubernetes.kubernetes_public_fip_pool }}{{- end -}}
{{- end -}}
