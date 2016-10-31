FROM hkumar/ubuntu-14.04.2:latest
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG ENTRY_POINT=docker_entrypoint.sh
ARG DEBIAN_FRONTEND=noninteractive
ARG CONTRAIL_REPO_URL
ARG SSHPASS
ARG CONTRAIL_ANSIBLE_TAR
ARG PACKAGES_LB="haproxy python-jinja2 keepalived supervisor jq"
ARG apt_install="apt-get install -yq --force-yes --no-install-recommends --no-install-suggests "

RUN sed -i "1ideb $CONTRAIL_REPO_URL ./" /etc/apt/sources.list
RUN var1=$(echo $CONTRAIL_REPO_URL | sed -r 's#http[s]?://([[:digit:]\.]+):.*#\1#') ; \
    echo "Package: *\nPin: origin \"$var1\"\nPin-Priority: 1001" > /etc/apt/preferences
RUN echo "APT::Get::AllowUnauthenticated \"true\";" > /etc/apt/apt.conf.d/99allowunauth
RUN apt-get update -qy && \
    $apt_install $PACKAGES_LB && \
    apt-get autoremove -yq  &&\
    rm -fr /usr/share/doc/* /usr/share/man/*

VOLUME ["/var/log", "/dev/log:/dev/log"]
COPY haproxy.cfg.j2 keepalived.conf.j2 entrypoint.sh /
COPY pyj2.py chk_ip_connectivity.sh /usr/local/bin/
COPY supervisor_configs /etc/supervisor/conf.d/
RUN chmod +x /entrypoint.sh /usr/local/bin/*
ENTRYPOINT /entrypoint.sh
