# 1. Introduction
This document talk about ansible unit test framework implementation.

# 2. Problem statement
Currently there is no way to do unit tests on any internal or external ansible code,
to test the changes without external dependencies. This cause necessity to run functional
tests on all changes and is costly because we have to support multiple scenarios and
cloud orchestrators - e.g single node, multi-node cluster, contrail with kubernetes,
openstack, openshift, mesos, etc.

It also would be difficult to cover all these scenarios in ci functional tests.

Also functional tests depending on various external factors like

* package availability or any dependency issues for packages may cause errors on
package installation.
* Any bug in application code may cause service start, registration, port check etc failed

# 3. Proposed solution
To implement a unit test framework with minimal or no external dependencies.

Here are various things we can test on ansible code

* package installation
* Configurations
* Service start/stop/restart
* Registering services to config api

Since ansible have no unit test framework, one have to execute the task to test the
outcome. And thus we can only reliably check "configurations" because other parts
have external dependencies. So it is proposed to start the framework covering
**only configruation changes**. Also most of the changes that would be happening
is configuration changes than any other stuffs.

There should be a system which run contrailctl with contrailctl configruations
or ansible with inventory directly in case of external code, with only configure
tag (which does only configurations and nothing else), and validate the resultant
configurations with expected values. It also should run ansible with check mode
which validate the syntax and the validity of parameters passed to each ansible tasks
as those tasks supported.

This approach can cover almost all possible scenarios (multi node/single node/kubernetes
/openstack/ or others and any combination of these) without need of actual containers
or services setup/running. It would be difficult to cover all those scenarios with
functional tests as it needed different setup to cover all of them.

All configurations should be validated and tested with this framework and any other
provisioning code for package installation, service management, cluster formation
logic etc will not be tested within this framework as they have external
dependencies as stated above and thus cannot reliably test them.

Test script also should handle preparing the test environment to make sure prerequisites
are met.
## 3.1 Alternatives considered
### Run single set of  contrail containers and run ansible code within it and test

An alternative method considered is to run single set of contrail containers and run
contrailctl/ansible in it and validate various things like package, configs, service etc.
But since this has lot of external dependencies which are mentioned in problem statement,
and is supposed to cover in ci functional tests.
Also it would be costly to cover all scenarios in functional tests.

### Create different small test scripts rather than values.yaml
Users will have to create lot of test scripts which would be doing the same thing (checking
a string in specific configuration file) and they need to be repeated in different scenarios
and then there may be another script to manage these test scripts (like testr to manage all
test scripts in python unit test framework). 

Rather we can have one script which read the configuration file, and expected configurtion
and values from values.yaml and verify them exist in appropriate configuration files.

# 4. Implementation
All tests will run ansible with check mode which validate the task execution logic and
inputs to each tasks and ansible syntax.

Different test scenarios will be implemented for different scenarios that we want to test
like single node with openstack, multi-node with openstack, multi-node with kubernetes,
multi-node with mesos etc.

Each test scenario will have its own directory under which it will have inputs required for
ansible or contrailctl run and a yaml file (may be named as values.yaml) which dictate the
expected values for different configurations in that scenario.

Also test scenarios may have prerequisites like directories to be existed in which the config
files will be written, ip addresses to be set etc. These preparation data is added there within
env.yaml and test script will refer this file to run preparatory steps.

A test script (test.py) that will:
* Iterate through all test scenario directories found under tests/ directory
* Prepare system based out of env.yaml
* run ansible or contrailctl with the inputs within each scenario
* Verify the outcome configurations with the expected values mentioned in the values.yaml
 file in each scenario directory
* Report the result
* Cleanup to revert preparation steps

User is supposed to install ansible and contrailctl may be in a python venv or in the system itself.
Each 


It also provide a entrypoint.sh to the container which prepare the system as above,
run tests and publish the results in specific reports directory within the host.

Sample controller.conf
```
[GLOBAL]
enable_webui_service = True
analyticsdb_list = ['10.204.216.58', '10.204.216.59', '10.204.216.60']
cloud_orchestrator = openstack
enable_config_service = True
config_server_list = ['10.204.216.58', '10.204.216.59', '10.204.216.60']
enable_control_service = True
controller_list = ['10.204.216.58', '10.204.216.59', '10.204.216.60']
analytics_list = ['10.204.216.58', '10.204.216.59', '10.204.216.60']
```

Corresponding values.yaml snippet
```
contrail-api.conf:
  DEFAULTS:
    zk_server_ip: "10.204.216.58:2181,10.204.216.59:2181,10.204.216.60:2181"
    rabbit_server: "10.204.216.58:5672,10.204.216.59:5672,10.204.216.60:5672"
    collectors: "10.204.216.58:8086 10.204.216.59:8086 10.204.216.60:8086"
    auth: keystone
    cassandra_server_list: "10.204.216.58:9160 10.204.216.59:9160 10.204.216.60:9160"
    listen_port: 8082
contrail-control.conf:
  DEFAULT:
    collectors: "10.204.216.58:8086 10.204.216.59:8086 10.204.216.60:8086"
    hostip: "10.204.216.58"
    hostname: node1
  IFMAP:
    rabbitmq_server_list: "10.204.216.58:5672 10.204.216.59:5672 10.204.216.60:5672"
    rabbitmq_user: guest
    rabbitmq_password: guest
    config_db_server_list: "10.204.216.58:9042 10.204.216.59:9042 10.204.216.60:9042"
......
......
......
```

sample env.yaml
```
---
# Set different options to set test environment
# This will be refered by prepare step by test runner and execute steps to
# prepare the test environment
prepare:
  # Setup a non-routeable ip address on the host to make ansible runnable
  # This is required as ansible code refer local ip address and match it with
  # the configuration provided.
  # If not provided, it will set first ip address from <component>_list
  # configuration from contrailctl config files (analytics_list[0] for analytics)
  network:
    ip:
      - 192.168.0.63/24
    gateway: 192.168.0.1
#    macaddress:
  # Directories to be created
  directories:
    - /etc/contrail/
    - /etc/contrail/dns
    - /etc/rabbitmq
    - /etc/cassandra
    - /usr/share/kafka/config
    - /etc/redis
    - /var/lib/rabbitmq
    - /var/lib/zookeeper
  files:
    - /etc/contrail/dns/contrail-named.conf
    - /etc/contrail/dns/contrail-rndc.conf

```
## 4.1. Internal code testing
Each scenario directories will have all contrailctl (controller.conf, analytics.conf,
analyticsdb.conf, agent.conf etc) configuration files with sample values and a values.yaml
file which contain expected values.

Test script will:
* Iterate through each scenario directories
* Run contrailctl with each configuration files and run tasks with "configure" tag,
* validate resultant configurations with the values from values.yaml
* Report the results

### 4.1.1 Changes required to the ansible code
* All configuration related tasks must be tagged as "configure" - this is already done
* All handlers should have an extra conditional "ansible_test_mode" and not 
to run handlers in case of anisble_test_mode is true

## 4.2. External ansible code testing
Each scenario directories will have an inventory.ini file and values.yaml.

Test script will:
* Iterate through each scenario directories
* Run ansible-playbook with inventory.ini file in each directory and run
tasks with "configure" tag
* Validate resultant configurations (contrailctl configurations) with values
from values.yaml
* Report the results

### 4.2.1 Changes required to the ansible code
* All contrailctl configuration code must be tagged as "configure"
