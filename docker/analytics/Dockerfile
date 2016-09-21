FROM hkumar/ubuntu-14.04.2:latest
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_REPO_URL
ARG CONTRAIL_ANSIBLE_TAR
ARG ENTRY_POINT=docker_entrypoint.sh
ARG SSHPASS
ARG DEBIAN_FRONTEND=noninteractive
ARG apt_install="apt-get install -yq --force-yes --no-install-recommends --no-install-suggests "
ARG ANSIBLE_INVENTORY="all-in-one"
ARG PACKAGES_CONTRAIL_ANALYTICS="contrail-openstack-analytics redis-server crudini jq python-pip"
RUN sed -i "1ideb $CONTRAIL_REPO_URL ./" /etc/apt/sources.list
RUN var1=$(echo $CONTRAIL_REPO_URL | sed -r 's#http[s]?://([[:digit:]\.]+):.*#\1#') ; \
    echo "Package: *\nPin: origin \"$var1\"\nPin-Priority: 1001" > /etc/apt/preferences
RUN echo "APT::Get::AllowUnauthenticated \"true\";" > /etc/apt/apt.conf.d/99allowunauth
RUN apt-get update -qy && \
    $apt_install $PACKAGES_CONTRAIL_ANALYTICS && \
    apt-get autoremove -yq  &&\
    rm -fr /usr/share/doc/* /usr/share/man/*
RUN pip install fabric==1.11.1 paramiko==1.17.0
VOLUME ["/var/log", "/var/crashes"]
EXPOSE 8081 8086
COPY *.sh *.j2 /
COPY redis.conf /etc/redis/
COPY supervisor_configs/ /etc/contrail/supervisord_analytics_files/
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
