FROM hkumar/ubuntu-14.04.2:latest
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG ENTRY_POINT=docker_entrypoint.sh
ARG DEBIAN_FRONTEND=noninteractive
ARG CONTRAIL_INSTALL_PACKAGE_URL
ARG PACKAGES_LB="haproxy python-jinja2 keepalived supervisor"

RUN wget -q --spider $CONTRAIL_INSTALL_PACKAGE_URL

RUN wget $CONTRAIL_INSTALL_PACKAGE_URL -O /contrail-install-packages.deb && \
    dpkg -i /contrail-install-packages.deb && \
    rm -f /contrail-install-packages.deb && \
    cd /opt/contrail/contrail_packages/ && ./setup.sh && \
    apt-get install -y --force-yes $PACKAGES_LB && \
    find /opt/contrail -mindepth 1 ! -name bin -delete; \
    apt-get -y autoremove && apt-get -y clean;

VOLUME ["/var/log", "/dev/log:/dev/log"]
COPY haproxy.cfg.j2 keepalived.conf.j2 entrypoint.sh /
COPY pyj2.py chk_ip_connectivity.sh /usr/local/bin/
COPY supervisor_configs /etc/supervisor/conf.d/
RUN chmod +x /entrypoint.sh /usr/local/bin/*
ENTRYPOINT /entrypoint.sh
