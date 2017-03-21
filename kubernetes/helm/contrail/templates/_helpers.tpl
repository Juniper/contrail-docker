{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "controller.fullname" -}}
{{- $name := default "controller" .Values.controllerNameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "agent.fullname" -}}
{{- $name := default "agent" .Values.agentNameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "globalConfig" -}}
    [GLOBAL]
{{- range $key, $val := .Values.global }}
    {{ $key }} = {{ $val }}
{{- end -}}
{{- end -}}

{{- define "agentConfig" -}}
    [AGENT]
{{- range $key, $val := .Values.agent }}
    {{ $key }} = {{ $val }}
{{- end -}}
{{- end -}}

{{- define "webuiConfig" -}}
    [WEBUI]
{{- range $key, $val := .Values.webui }}
    {{ $key }} = {{ $val }}
{{- end -}}
{{- end -}}
