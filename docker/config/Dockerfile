FROM hkumar/ubuntu-14.04.2:latest
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_INSTALL_PACKAGE_URL
ARG ENTRY_POINT=docker_entrypoint.sh
ARG SSHPASS
ARG DEBIAN_FRONTEND=noninteractive
ENV SKU=liberty
ARG PACKAGES_CONTRAIL_CONFIG="contrail-lib contrail-config contrail-f5 neutron-plugin-contrail contrail-setup \
                              contrail-utils contrail-config-openstack supervisor neutron-server python-neutron-lbaas \
                              python-novaclient python-keystoneclient haproxy euca2ools python-qpid python-iniparse \
                              python-bottle ifmap-server ifmap-python-client keepalived contrail-nodemgr crudini \
                              rabbitmq-server"

RUN wget -q --spider $CONTRAIL_INSTALL_PACKAGE_URL

RUN wget $CONTRAIL_INSTALL_PACKAGE_URL -O /contrail-install-packages.deb && \
    dpkg -i /contrail-install-packages.deb && \
    rm -f /contrail-install-packages.deb && \
    cd /opt/contrail/contrail_packages/ && ./setup.sh && \
    apt-get install -y --force-yes $PACKAGES_CONTRAIL_CONFIG; \
    find /opt/contrail -mindepth 1 -maxdepth 1 ! -name bin -exec rm -fr {} \; ; \
    apt-get -y autoremove && apt-get -y clean;

VOLUME ["/var/log", "/var/crashes"]
COPY common.sh configure.sh entrypoint.sh *.j2 /
COPY supervisor_configs/ /etc/contrail/supervisord_config_files/
COPY pyj2.py /usr/local/bin/
RUN chmod +x /entrypoint.sh /usr/local/bin/pyj2.py
ENTRYPOINT /entrypoint.sh



