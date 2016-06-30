#!/usr/bin/env python

import sys
import os
import re
sys.path.insert(0,"/opt/contrail/utils")
from fabric.tasks import execute
from fabric.main import load_fabfile
from fabric import state
from fabfile.tasks.install import *
from fabfile.tasks.provision import *
@task
@roles('cfgm')
def install_docker():
    """ At this moment, only ubuntu is supported
    """
    ostype = detect_ostype()
    if ostype in ['ubuntu']:
        cmd = "apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D; "
        cmd += "echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main' > /etc/apt/sources.list.d/docker.list; "
        cmd += "apt-get -q update; "
        cmd += "DEBIAN_FRONTEND=noninteractive apt-get install -q -y --force-yes docker-engine; "
        sudo(cmd)
    else:
        print("Unsupported Operating system - %s" % ostype)

@task
def load_docker_image(image_url):
    image_file = os.path.basename(image_url)
    cmd = "wget -O /tmp/%s %s; " % (image_file, image_url)
    cmd += "docker load < /tmp/%s" % (image_file)
    run(cmd)


@task
def start_container(run_command):
    run(run_command)

@task
@roles('cfgm')
def initialize(package_path):
    package_name = os.path.basename(package_path)
    if not exists("/opt/contrail/contrail_packages/setup.sh"):
        put(package_path, "/tmp/")
        cmd = "dpkg -i /tmp/%s; " % package_name
        cmd += "cd /opt/contrail/contrail_packages; bash setup.sh"
        sudo(cmd)

@task
@roles('build')
def install_on_host(*tgzs, **kwargs):
    reboot = kwargs.get('reboot', 'True')
    execute('pre_check')
    execute('create_installer_repo')
    execute(create_install_repo, *tgzs, **kwargs)
    execute(create_install_repo_dpdk)
    execute('install_orchestrator')
    execute(install_docker)
    if 'vcenter_compute' in env.roledefs:
        execute(install_vcenter_compute)
    execute(install_vrouter)
    if getattr(env, 'interface_rename', True):
        print "Installing interface Rename package and rebooting the system."
        execute(install_interface_name, reboot)
        #Clear the connections cache
        connections.clear()
    execute('reboot_on_kernel_update', reboot)

@task
@roles('build')
def setups(reboot='True'):
    execute(enable_haproxy, roles=["cfgm"])
    nworkers = 1
    execute(fixup_restart_haproxy_in_all_cfgm, nworkers, roles=["cfgm"])

@task
@roles('build')
def setup(reboot='True'):
    with settings(warn_only=True):
        execute('setup_common')
        execute('setup_ha')
        execute('setup_rabbitmq_cluster')
        execute('increase_limits')
        contrail_database_image_url = "http://10.204.217.158/images/docker-images/contrail/contrail-database-liberty-3.0.2.0-35.tar.gz"
        execute(load_docker_image, contrail_database_image_url, roles=["cfgm"])
        start_database_cmd = "docker run --net=host --name contrail-database -e IPADDRESS=10.204.217.91 -e CFGM_IP=10.204.217.91 -e SEED_LIST=10.204.217.91 -e ZOOKEEPER_IP_LIST=10.204.217.91 -e DATABASE_INDEX=1 -e MINIMUM_DISKGB=10 -itd contrail-database-liberty:3.0.2.0-35"
        execute(start_container, start_database_cmd, roles=["cfgm"])
    #    execute('setup_database') - Containerized
    #    execute('verify_database') - verify_service will not work on container, would need to have a replacement
    #    execute('fixup_mongodb_conf') - This need to be done on container, skipping as of now
    #    execute('setup_mongodb_ceilometer_cluster') - this is required but skipping as of now (may be ceilometer is not setup at this stage
        execute('setup_orchestrator')
        os_token = local("cat /etc/contrail/service.token", capture=True)
        contrail_config_image_url = "http://10.204.217.158/images/docker-images/contrail/contrail-config-liberty-3.0.2.0-35.tar.gz"
        execute(load_docker_image, contrail_config_image_url, roles=["cfgm"])
        start_config_cmd = "docker run --name contrail-config --net=host -e NEUTRON_PASSWORD=secret123 -e OS_TOKEN=%s  -e OS_PASSWORD=secret123 -e IPADDRESS=10.204.217.91 -e DISCOVERY_SERVER_PORT=9110 -itd contrail-config-liberty:3.0.2.0-35" % os_token
        execute(start_container, start_config_cmd, roles=["cfgm"])

        contrail_control_image_url = "http://10.204.217.158/images/docker-images/contrail/contrail-control-liberty-3.0.2.0-35.tar.gz"
        execute(load_docker_image, contrail_control_image_url, roles=["cfgm"])
        start_control_cmd = "docker run --name contrail-control --net=host -e IPADDRESS=10.204.217.91 -itd contrail-control-liberty:3.0.2.0-35"
        execute(start_container, start_control_cmd, roles=["cfgm"])

        contrail_analytics_image_url = "http://10.204.217.158/images/docker-images/contrail/contrail-analytics-liberty-3.0.2.0-35.tar.gz"
        execute(load_docker_image, contrail_analytics_image_url, roles=["cfgm"])
        start_analytics_cmd = "docker run --name contrail-analytics --net=host -e IPADDRESS=10.204.217.91 -itd contrail-analytics-liberty:3.0.2.0-35"
        execute(start_container, start_analytics_cmd, roles=["cfgm"])
        execute(enable_haproxy, roles=["cfgm"])
        nworkers = 1
        execute(fixup_restart_haproxy_in_all_cfgm, nworkers)
    #    execute('setup_cfgm')  - Contanerized
    #   Setup haproxy - configure backends etc - this is eventually going to be a container
    #    execute('verify_cfgm') - Nothing as of now, will need to check
    #    execute('setup_control')   - Containerized
    #    execute('verify_control') - Nothing as of now, will need to check
    #    execute('setup_collector') - Containerized
    #    execute('verify_collector') - Nothing as of now, will need to check
    #    execute('setup_webui') - Containerized
    #    execute('verify_webui') - Nothing as of now, will check
        if 'vcenter_compute' in env.roledefs:
            execute('setup_vcenter_compute')
        execute('setup_vrouter')
        execute('prov_config') # - This should be done in config node (while starting container) or on orchestrator
        execute('prov_database')  # This should be done in config container or or on orchestrator
        execute('prov_analytics')
        execute('prov_control_bgp')
        execute('prov_external_bgp')
        execute('prov_metadata_services')
        execute('prov_encap_type') # till this done
        execute('setup_remote_syslog')
        execute('add_tsn', restart=False)
        execute('add_tor_agent', restart=False)
        execute('increase_vrouter_limit')
        execute('setup_vm_coremask')
        if get_openstack_internal_vip():
            execute('setup_cluster_monitors')
        if reboot == 'True':
            print "Rebooting the compute nodes after setup all."
            execute('compute_reboot')
            #Clear the connections cache
            connections.clear()
            execute('verify_compute')
        execute('setup_nova_aggregate')
#end setup_all


def main():
    docs, callables, default = load_fabfile('/opt/contrail/utils/fabfile')
    state.commands.update(callables)
    package_path = "/tmp/contrail-install-package.deb"

    if os.path.exists(package_path):
        execute(initialize, package_path)
        execute(install_on_host, reboot=False)
        execute(setup)
    else:
        print("Failed to get package from %s" % package_url)
    return True

if __name__ == '__main__':
    main()