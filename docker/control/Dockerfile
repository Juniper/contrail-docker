FROM hkumar/ubuntu-14.04.2:latest
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_INSTALL_PACKAGE_URL
ARG ENTRY_POINT=docker_entrypoint.sh
ARG SSHPASS
ARG DEBIAN_FRONTEND=noninteractive
ENV SKU=liberty
ARG PACKAGES_CONTRAIL_CONTROL="contrail-openstack-control crudini"

RUN wget -q --spider $CONTRAIL_INSTALL_PACKAGE_URL

RUN wget $CONTRAIL_INSTALL_PACKAGE_URL -O /contrail-install-packages.deb && \
    dpkg -i /contrail-install-packages.deb && \
    rm -f /contrail-install-packages.deb && \
    cd /opt/contrail/contrail_packages/ && ./setup.sh && \
    apt-get install -y --force-yes $PACKAGES_CONTRAIL_CONTROL && \
    find /opt/contrail -mindepth 1 ! -name bin -delete; \
    apt-get -y autoremove && apt-get -y clean;
VOLUME ["/var/log", "/var/crashes"]
COPY configure.sh common.sh entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh



