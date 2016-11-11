FROM ubuntu:14.04.5
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_INSTALL_PACKAGE_URL
ARG CONTRAIL_REPO_URL
ARG CONTRAIL_ANSIBLE_TAR
ARG ENTRY_POINT=docker_entrypoint.sh
ARG SSHPASS
ARG DEBIAN_FRONTEND=noninteractive
ARG apt_install="apt-get install -yq --force-yes --no-install-recommends --no-install-suggests "
ARG ANSIBLE_INVENTORY="all-in-one"
ARG PACKAGES_CONTRAIL_AGENT="contrail-lib contrail-utils contrail-vrouter-utils python-contrail-vrouter-api \
    python-opencontrail-vrouter-netns contrail-vrouter-agent contrail-vrouter-init contrail-nodemgr crudini jq"

RUN sed -i "1ideb $CONTRAIL_REPO_URL ./" /etc/apt/sources.list
RUN var1=$(echo $CONTRAIL_REPO_URL | sed -r 's#http[s]?://([[:digit:]\.]+):.*#\1#') ; \
    echo "Package: *\nPin: origin \"$var1\"\nPin-Priority: 1001" > /etc/apt/preferences
RUN echo "APT::Get::AllowUnauthenticated \"true\";" > /etc/apt/apt.conf.d/99allowunauth
RUN apt-get update -qy && \
    $apt_install $PACKAGES_CONTRAIL_AGENT && \
    apt-get autoremove -yq  &&\
    rm -fr /usr/share/doc/* /usr/share/man/*
RUN cp -rf /usr/src/ /usr/src.orig/
VOLUME ["/var/log", "/var/crashes", "/usr/src"]
COPY *.sh *.j2 /
EXPOSE 8081 8086
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
