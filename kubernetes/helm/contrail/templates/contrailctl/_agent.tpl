{{/* ================================================================ */}}
{{/* AGENT container specific sections are formed using this template */}}
{{/* ================================================================ */}}
{{- define "contrail.agentConfig" -}}
[AGENT]

{{ if eq .hostOs "centos" }}compile_vrouter_module = False
{{ else }}compile_vrouter_module = {{ .conf.agent.compileVrouterModule | default "True" }}{{ end }}

{{ if not .conf.agent.ctrlDataNetwork }}#{{ end }}ctrl_data_network = {{ .conf.agent.ctrlDataNetwork }}

{{- if not .conf.agent.qosQueueIdList -}}{{- $_ := set .conf.agent "qosQueueIdList" list -}}{{- end -}}
{{ if not .conf.agent.qosQueueIdList }}#{{ end }}qos_queue_id_list = [{{- range .conf.agent.qosQueueIdList -}}{{ . | quote  }},{{ end }}]

{{- if not .conf.agent.qosLogicalQueueList -}}{{- $_ := set .conf.agent "qosLogicalQueueList" list -}}{{- end -}}
{{ if not .conf.agent.qosLogicalQueueList }}#{{ end }}qos_logical_queue_list = [{{- range .conf.agent.qosLogicalQueueList -}}{{ . | quote  }},{{ end }}]

{{ if not .conf.agent.qosDefaultNicQueue }}#{{ end }}qos_default_nic_queue = {{ .conf.agent.qosDefaultNicQueue }}

{{ if not .conf.agent.qosPriorityTagging }}#{{ end }}qos_priority_tagging = {{ .conf.agent.qosPriorityTagging }}

{{- if not .conf.agent.priorityIdList -}}{{- $_ := set .conf.agent "priorityIdList" list -}}{{- end -}}
{{ if not .conf.agent.priorityIdList }}#{{ end }}priority_id_list = [{{- range .conf.agent.priorityIdList -}}{{ . | quote  }},{{ end }}]

{{- if not .conf.agent.prioritySchedulingList -}}{{- $_ := set .conf.agent "prioritySchedulingList" list -}}{{- end -}}
{{ if not .conf.agent.prioritySchedulingList }}#{{ end }}priority_scheduling_list = [{{- range .conf.agent.prioritySchedulingList -}}{{ . | quote  }},{{ end }}]

{{- if not .conf.agent.priorityBandwidthList -}}{{- $_ := set .conf.agent "priorityBandwidthList" list -}}{{- end -}}
{{ if not .conf.agent.priorityBandwidthList }}#{{ end }}priority_bandwidth_list = [{{- range .conf.agent.priorityBandwidthList -}}{{ . | quote  }},{{ end }}]

{{ if not .conf.agent.vrouterModuleParams }}#{{ end }}vrouter_module_params = {{ .conf.agent.vrouterModuleParams }}
[HYPERVISOR]
{{ if not .conf.agent.hypervisor.type }}#{{ end }}type = {{ .conf.agent.hypervisor.type | default "kvm" }}
{{- end -}}
