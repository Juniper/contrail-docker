# Contrail-docker

This is an effort to containerize contrail subsystems. The idea is to reduce the complexity to deploy contrail and to
provide straight forward, simple way to deploy and operate contrail.

In the initial effort, all contrail controller and vrouter agent application will be containerized. Openstack
containers would be implemented as a second step.

Here are the initial containers would be and what they contains:

* contrail-controller: This container contain *all* contrail applications that makes an SDN controller - i.e config,
 control, webui, cassandra (db for config only), zookeeper, rabbitmq etc.
* contrail-analytics: This container will have analytics applications running
* contrail-adb: This will have cassandra db to serve as analytics db.
* contrail-vrouter-agent: This is going to have vrouter agent running - this may be only used with future, container
  orchestration systems like kubernetes
* contrail-lb: This will have all haproxy, keepalive etc which provide a load balancing and HA to the sytem. This is
    an optional one, and people may choose to use their own loadbalancing systems. Note that none of the above
    containers will have haproxy and keepalive setup in them and we are taking that feature out of them.

One of the important consideration we taken is that, this effort is starting with **ONLY** contrail components and
**NO** openstack. Idea is to start with **only** contrail components as core and add more components to it as needed.
This will enable to us develop the system that is composable - when we needed to use this with different cloud/container
orchestration systems like openstack, kubernetes, mesos etc.

## More insights on requirements/design decisions

* We are going with multi-process containers and NOT going with per process containers at this moment because that would
  probably complicate the system more than currently.
* All logs and some data directories should be mounted. This will eliminate any performance issues and reduce the need
  of logging into the containers.
* Minimal configuration complexity: There should be a inifile based configuration - one per container and that should
  have all configurations for the applications running in that container. For example, all applications running in
  "controller" container should be configured with single inifile which would be available on the host (it will be
  mounted to the container so the changes wil be visible to the container and base host).
* There should be a toolset developed (we just named it as contrailctl) to handle the above mentioned configurations and
   some high level tasks such as mentioend below
   * One should be able to perform high level operations using this tool like add/remove a controller/compute nodes
   * Single inifile configuration should be synced with internal per application configurations - and it should support
     a bidirectional config conversions
   * May be some operational tasks like restarting certain applications etc
* Minimal external orchestration needs: The container should be self-contained and should handle all the "magic"
    to configure himself with minimal external orchestration needs - so ideally the job of external provisioning system
     should be as simple as create custom configuration in inifile per controller (e.g /etc/contrailctl/controller.conf)
     and start the containers. Rest of the things should be handled inside the containers
* We should have single tool used for all levels of build/deployment/provisioning - we decided that to be *ansible*
* Regarding containerization tool, we decided to go with docker


## Brief on basic changes when using docker containers

When we use containers, the entire deployment process will be completely seperated in two stages

1. build the container image
    In build stage, all the packages will be installed and some basic common configuration is done and build a generic
image which is ready to configure and will run every environment. So here we are going to create the container images
for each containers separately. In this stage build tool will have no idea about the environment where these
containers going to run. So it is like we create deb/rpm packages but here we get a high level sytem image which
have all those packages installed.

    This will reduce any package installation conflicts and other problems in customer environments as all these problems
will be handled in the build stage itself. These containers are all packages installed, prebuilt systems. All they
need is provide customer/environment specific configurations.

    Build is happening in our nightly build environment - so just after the package build and other stuffs, a container
image build job also be running, which consume those packages that built and create container images. These images
we saved as artifacts and will be shipped to the customers/end users.

2. deploy/provision the containers
    In this stage, one will take the container images, and run them with appropriate inputs as mentioned in the previous
    section. This comes setting up environment specific configurations, any orchestration, and starting the containers
    from pre-built container images.

    This happen in the environments directly where the system is going to setup.


## Related repositories

https://github.com/Juniper/contrail-docker: This repository will have all container building and supporting code.

https://github.com/Juniper/contrail-ansible: This repo will have all ansible code to support build, configure and
orchestrate the containers built and overall system setup.
