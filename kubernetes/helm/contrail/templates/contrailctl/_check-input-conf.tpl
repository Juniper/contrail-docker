{{/* =============================================================== */}}
{{/*           Check existence of the input values                   */}}
{{/*    if not defined then set the correct data struct              */}}
{{/* =============================================================== */}}

{{- define "contrail.checkInputConfStruct" -}}

{{- if not .hostOs -}}{{- set . "hostOs" "ubuntu" -}}{{- end -}}
{{- if not .conf -}}{{- set . "conf" dict -}}{{- end -}}
{{- if not .conf.global -}}{{- set .conf "global" dict -}}{{- end -}}
{{- if not .conf.global.controller -}}{{- set .conf.global "controller" dict -}}{{- end -}}
{{- if not .conf.global.analyticsdb -}}{{- set .conf.global "analyticsdb" dict -}}{{- end -}}
{{- if not .conf.global.analytics -}}{{- set .conf.global "analytics" dict -}}{{- end -}}
{{- if not .conf.global.config -}}{{- set .conf.global "config" dict -}}{{- end -}}
{{- if not .conf.global.webui -}}{{- set .conf.global "webui" dict -}}{{- end -}}
{{- if not .conf.global.external -}}{{- set .conf.global "external" dict -}}{{- end -}}
{{- if not .conf.global.ssl -}}{{- set .conf.global "ssl" dict -}}{{- end -}}
{{- if not .conf.global.apiserver -}}{{- set .conf.global "apiserver" dict -}}{{- end -}}
{{- if not .conf.global.neutron -}}{{- set .conf.global "neutron" dict -}}{{- end -}}

{{- if not .conf.global.controller.nodes -}}{{- set .conf.global.controller "nodes" list -}}{{- end -}}
{{- if not .conf.global.config.nodes -}}{{- set .conf.global.config "nodes" list -}}{{- end -}}
{{- if not .conf.global.webui.nodes -}}{{- set .conf.global.webui "nodes" list -}}{{- end -}}
{{- if not .conf.global.analytics.nodes -}}{{- set .conf.global.analytics "nodes" list -}}{{- end -}}
{{- if not .conf.global.analyticsdb.nodes -}}{{- set .conf.global.analyticsdb "nodes" list -}}{{- end -}}

{{- if not .conf.global.external.rabbitmqServers -}}{{- set .conf.global.external "rabbitmqServers" list -}}{{- end -}}
{{- if not .conf.global.external.controllerZookeeperServers -}}{{- set .conf.global.external "controllerZookeeperServers" list -}}{{- end -}}
{{- if not .conf.global.external.analyticsdbZookeeperServers -}}{{- set .conf.global.external "analyticsdbZookeeperServers" list -}}{{- end -}}
 
{{- if not .conf.controller -}}{{- set .conf "controller" dict -}}{{- end -}}
{{- if not .conf.control -}}{{- set .conf "control" dict -}}{{- end -}}
{{- if not .conf.control.logPortInfo -}}{{- set .conf.control "log_port_info" dict -}}{{- end -}}

{{- if not .conf.contrailAPI -}}{{- set .conf "contrail_api" dict -}}{{- end -}}
{{- if not .conf.contrailAPI.logPortInfo -}}{{- set .conf.contrailAPI "log_port_info" dict -}}{{- end -}}

{{- if not .conf.schema -}}{{- set .conf "schema" dict -}}{{- end -}}
{{- if not .conf.schema.logPortInfo -}}{{- set .conf.schema "log_port_info" dict -}}{{- end -}}

{{- if not .conf.svcMonitor -}}{{- set .conf "svc_monitor" dict -}}{{- end -}}
{{- if not .conf.svcMonitor.logPortInfo -}}{{- set .conf.svcMonitor "log_port_info" dict -}}{{- end -}}

{{- if not .conf.deviceManager -}}{{- set .conf "device_manager" dict -}}{{- end -}}
{{- if not .conf.deviceManager.logPortInfo -}}{{- set .conf.deviceManager "log_port_info" dict -}}{{- end -}}

{{- if not .conf.dns -}}{{- set .conf "dns" dict -}}{{- end -}}
{{- if not .conf.dns.logPortInfo -}}{{- set .conf.dns "log_port_info" dict -}}{{- end -}}

{{- if not .conf.analyticsAPI -}}{{- set .conf "analytics_api" dict -}}{{- end -}}
{{- if not .conf.analyticsAPI.logPortInfo -}}{{- set .conf.analyticsAPI "log_port_info" dict -}}{{- end -}}

{{- if not .conf.analyticsCollector -}}{{- set .conf "analytics_colletor" dict -}}{{- end -}}
{{- if not .conf.analyticsCollector.logPortInfo -}}{{- set .conf.analytics_colletor "log_port_info" dict -}}{{- end -}}

{{- if not .conf.alarmGen -}}{{- set .conf "alarm_gen" dict -}}{{- end -}}
{{- if not .conf.alarmGen.logPortInfo -}}{{- set .conf.alarmGen "log_port_info" dict -}}{{- end -}}

{{- if not .conf.queryEngine -}}{{- set .conf "query_engine" dict -}}{{- end -}}
{{- if not .conf.queryEngine.logPortInfo -}}{{- set .conf.queryEngine "log_port_info" dict -}}{{- end -}}

{{- if not .conf.topology -}}{{- set .conf "topology" dict -}}{{- end -}}
{{- if not .conf.topology.logPortInfo -}}{{- set .conf.topology "log_port_info" dict -}}{{- end -}}

{{- if not .conf.snmpCollector -}}{{- set .conf "snmp_collector" dict -}}{{- end -}}
{{- if not .conf.snmpCollector.logPortInfo -}}{{- set .conf.snmpCollector "log_port_info" dict -}}{{- end -}}

{{- if not .conf.webui -}}{{- set .conf "webui" dict -}}{{- end -}}

{{- if not .conf.rabbitmq -}}{{- set .conf "rabbitmq" dict -}}{{- end -}}

{{- if not .conf.configdb_cassandra -}}{{- set .conf "configdb_cassandra" dict -}}{{- end -}}

{{- if not .conf.analyticsdb_cassandra -}}{{- set .conf "analyticsdb_cassandra" dict -}}{{- end -}}

{{- if not .conf.agent -}}{{- set .conf "agent" dict -}}{{- end -}}
{{- if not .conf.agent.hypervisor -}}{{- set .conf.agent "hypervisor" dict -}}{{- end -}}

{{- if not .conf.kubernetes -}}{{- set .conf "kubernetes" dict -}}{{- end -}}

{{- if not .conf.kubernetesVNC -}}{{- set .conf "kubernetesVNC" dict -}}{{- end -}}

{{- end -}}
