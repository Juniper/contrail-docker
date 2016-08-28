FROM hkumar/ubuntu-14.04.2:latest
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_INSTALL_PACKAGE_URL
ARG ENTRY_POINT=docker_entrypoint.sh
ARG SSHPASS
ARG DEBIAN_FRONTEND=noninteractive
ENV SKU=liberty
ARG PACKAGES_CONTRAIL_AGENT="contrail-lib contrail-utils contrail-vrouter-utils python-contrail-vrouter-api \
    python-opencontrail-vrouter-netns contrail-vrouter-agent contrail-vrouter-init crudini jq"

RUN wget -q --spider $CONTRAIL_INSTALL_PACKAGE_URL

RUN wget $CONTRAIL_INSTALL_PACKAGE_URL -O /contrail-install-packages.deb && \
    dpkg -i /contrail-install-packages.deb && \
    rm -f /contrail-install-packages.deb && \
    cd /opt/contrail/contrail_packages/ && ./setup.sh && \
    apt-get install -y --force-yes $PACKAGES_CONTRAIL_AGENT; \
    find /opt/contrail -mindepth 1 -maxdepth 1 ! -name bin -exec rm -fr {} \; ; \
    apt-get -y autoremove && apt-get -y clean;
RUN cp -rf /usr/src/ /usr/src.orig/
VOLUME ["/var/log", "/var/crashes", "/usr/src"]
COPY *.sh *.j2 /
EXPOSE 8081 8086
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
