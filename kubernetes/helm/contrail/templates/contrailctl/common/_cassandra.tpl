{{/* =============================================================== */}}
{{/* Cassandra config for contrailctl is formed using this template */}}
{{/* Below are the defined fields as part of this template */}}
{{/* 	- commitlog_dir */}}
{{/* 	- data_dirs */}}
{{/* =============================================================== */}}

{{- define "contrail.cassandraConfig" -}}

[CASSANDRA]
{{ if not .commitLogDir }}#{{ end }}commitlog_dir = {{ .commitLogDir | default "/var/lib/cassandra/commitlog" }}
{{ if not .dataDirs }}#{{- $_ := set . "dataDirs" list "/var/lib/cassandra/data" -}}{{ end }}data_dirs = [{{- range .dataDirs -}}{{ . | quote  }},{{ end }}]

{{-  end -}}
