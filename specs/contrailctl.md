# contrailctl - a tool to configure and do high level operations for contrail-docker containers
It is decided to use a per container ini config file which would be kep in the base host to make that config file
management easy - users doesnt have to login to the container to update that file. The default location of these config
files is /etc/contrailctl/ under which per container files are placed e.g controller.conf is for controller,
analytics.conf for analytics, adb.conf for analytics db etc.

contrailctl is a tool which help to configure the services inside the container to be in sync with container specific
config files. Also it is used to do certain high level operations like adding a controller node etc, and may be in future
it may be used to do various other operations too.

## contrailctl design in more detail

In essense, contrailctl will do two basic operations at this moment.

1. Sync the config entries there in /etc/contrailctl with running system inside the container - this is done by updating
ansible variables in different levels and running ansible inside the container to sync the services in it with new
configurations updated.
2. Commit certain section of container config file so that internal service configuration is updated.
2. Do high level operations like add new node, remove node, disable certain service (e.g one wanted to migrate rabbitmq
to an external system) etc. In this case, contrailctl will do appropriate changes in config files in /etc/contrailctl
and sync the services inside the container with the configurations.

In any given time, config files in the /etc/contrailctl should be source of truth, which may be made possible with

1. using an auto sync mechanism - like poll these files for changes in certain frequency and run the update to services
 inside the container.
2. a manual sync subcommand: in this case, once somebody change the contrailctl config files manually, he have to run
sync subcommand (like "contrailctl config sync") which will sync the configs to the services inside the container

NOTE: In case of #1, we would have handle any situation when all individual services get restarted because of asynchronous
 operations, which may cause a downtime. This may be handled by adding some coordination code, which may be done later
 In case of #2, there are chances that users updated the config files and missed to do manual "sync", and this may cause
 inconsistencies in the internal service configurations.


### contrailctl to manage files under /etc/contrailctl/
This would be required when somebody decided to run contrailctl subcommands to do some high level operations (as
mentioned above), without editing /etc/contrailctl files. In this case contrailctl to do

* Verify the consistency of /etc/contrailctl/ files
    * Any syntax error in existing files before a change
    * Verify any uncommited changes - i.e any configurations in /etc/contrailctl that are NOT applied to the services/
    service configurations
* If verification is successful, add appropriate changes in /etc/contrailctl config files to make the operation successful
* Then run config sync code to sync the configuration with internal services

### contrailctl to do config sync for the config files under /etc/contrailctl
This is to make sure the services inside the containers are consistent with the configuration under /etc/contrailctl.
This may be happen automatically in certain (configurable) duration, and/or manually using "config sync" subcommand.

Essentially what this operation does is that, it will read the config files from /etc/contrailctl and update ansible
variables in various groupvars/ yaml files appropriately and ansible-playbook reconfigure the services and restart them.

### More detail about internal working
In its basic form, contrailctl does below things:
* Read container specific master_config file from /etc/contrailctl
* Map those configs to internal ansible variable mappings based out of map.*_PARAM_MAP - which is a dict to
  resolve one-to-one or one-to-many mappings for entries in master_config. Default mapping is <section name>_<param name>.
  For example, if /etc/contrailct/controller.conf has an entry "server_port" in the section "DISCOVERY", the default mapping
  in case there is no map entries in in map.CONTROLLER_PARAM_MAP, is discovery_server_port. But in case it map to
  "discovery_port" in map dict, it will map to that param.

  maps.*_PARAM_MAP may have one-to-many mappings for example, server_list in GLOBAL section will have one-to-many maps
  as server_list would add/update multiple ansible variables - like rabbit_servers, controller_servers, configdb_servers etc

* Verify if there any config is updated, Run below steps in case of configs updated,
    * Write mapped variables to container specific variable files in contrail-ansible - ansible would be reading from the
 variables from these files - by default they are kept in /contrail-ansible/playbooks/vars/<high level component name>.yml
 e.g /contrail-ansible/playbooks/vars/contrail_controller.yml.
    * Run ansible-playbook to update the service configs within the container
* In case there is no configs get updated, just exit with appropriate message

## contrailctl operations
Here are the major operations identified in initial stage.

1. contrailctl config sync [section] [param] [-f|--force] - This is to sync the entire configs from master_configs within
    /etc/contrailctl to service configs within the container. Optional section and param will restrict the data to be
    synced to specific section/param. Optional force option would do ansible run even if there is no config change to be
    synced.
2. contrailctl node add <node_type> <node details> - This operation is to add a node of type node_type, various node
    details like node_ip etc need to be provided. This will trigger reconfigurations on various configs and cluster
    reformations.
3. contrailctl node delete node_name - delete the node from various configurations. This will trigger reconfigurations
    on various configs and cluster reformations.
4. contrailctl config/node show/info/list - get infos about various configs
