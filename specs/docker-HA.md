# Introduction
The purpose of this document is to describe the requirements and design considerations for deploying 
containerized contrail subsystems in High Availability mode.

Following container subsystems can be deployed in HA mode,

- **contrail-lb**
- **contrail-controller**
- **contrail-analytics**
- **contrail-analyticsdb**
 
 
## contrail-lb
Contrail loadbalancer container **contrail-lb** runs HAProxy and BIRD(http://bird.network.cz/?get_doc&f=bird-6.html) protocol
- **HAProxy**: Used to loadbalance across the mulitple instance of contrail services
- **BIRD**: To deploy **contrail-lb** in Highly Available mode.

**contrail-lb** containers are expected to be deployed in different set of hosts. However it can also be deployed
in the same hosts where **contrail-controller** containers are deployed.


## contrail-controller
Contrail controller container **contrail-controller** runs following services that can be
scaled/clustered,

- **contrail-api**: Scaled up; loadbalanced by HAProxy running in the **contrail-lb** containers.
                     All clients will connect to the Loadbalancer IP to communicate with contrail-api.

- **contrail-discovery**: Scaled up; loadbalanced by HAProxy running in the **contrail-lb** containers.
                     All clients will connect to the Loadbalancer IP to communicate with contrail-discovery.
                     
- **cassandra**: Clustered; cassandra/client libraries has got in-built loadbalancing and failure detection 
                 mechanisam, So no need for cassandra to be behind HAProxy. However mulitple instances needs
                 to be clustered during depolyment of **contrail-controller** containers. All clients will 
                 connect to list of contrail-controller container ip's to communicate with cassandra. 
                 
- **zookeeper**: Clustered; zookeeper/client libraries has got in-built High avalability using 
                 leader/follower architecture, So no need for zookeeper to be behind HAProxy. However mulitple
                 instances needs to be clustered during depolyment of **contrail-controller** containers.
                 All clients will connect to list of contrail-controller container ip's to communicate with zookeeper. 
                 
- **rabbitmq**: Clustered; rabitmq/client libraries can handle multiple rabbit. However mulitple instances needs
                to be clustered and mirrorind the Queues during depolyment of **contrail-controller** containers.
                All clients will connect to list of contrail-controller container ip's to communicate with rabbitmq. 

**NOTE:** Only ODD number of contrail-controllers are supported as we have a limitation with zookeeper for
          leader/follower election.


## contrail-analytics
Contrail analytics container **contrail-analytics** runs **contrail-analytics-api** service that can be
scaled.

- **contrail-analytica-api**: Scaled up; loadbalanced by HAProxy running in the **contrail-lb** containers.
                              All clients will connect to the Loadbalancer IP to communicate with to 
                              contrail-analytics-api.

## contrail-analyticsdb
Contrail analytcsdb container **contrail-controller** runs following services that can be clustered,

- **cassandra**: Clustered; cassandra/client libraries has got in-built loadbalancing and failure detection 
                 mechanisam, So no need for cassandra to be behind HAProxy. However mulitple instances needs
                 to be clustered during depolyment of **contrail-analyticsdb** containers. All clients will 
                 connect to list of contrail-analyticsdb container ip's to communicate with cassandra. 

- **kafka**: Clusterd; Kafka uses zookeeper cluster running in the **contrail-controller** containers. Multiple
             instances of kafka needs to be clusters during deployment of **contrail-analyticsdb** containers. 
             All clients will connect to list of contrail-analyticsdb container ip's to communicate with kafka.


## Related repositories

https://github.com/Juniper/contrail-docker: This repository will have all container building and supporting code.

https://github.com/Juniper/contrail-ansible: This repo will have all ansible code to support build, configure and
orchestrate the containers built and overall system setup.
