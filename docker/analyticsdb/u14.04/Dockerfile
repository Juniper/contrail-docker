FROM hkumar/ubuntu:14.04.5
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_REPO_URL
ARG CONTRAIL_ANSIBLE_TAR
ARG http_proxy
ARG https_proxy
ARG no_proxy
ARG DEBIAN_FRONTEND=noninteractive
ARG apt_install="apt-get install -yq --force-yes --no-install-recommends --no-install-suggests "
ENV ANSIBLE_INVENTORY="all-in-one"
ARG PACKAGES_ANSIBLE="ansible python-configparser"
ARG CONTRAIL_REPO_MIRROR_SNAPSHOT=12032016
COPY contrail-ubuntu-mirror.key /
RUN apt-key add /contrail-ubuntu-mirror.key;\
    echo > /etc/apt/sources.list ;\
    echo "deb $CONTRAIL_REPO_URL ./" > /etc/apt/sources.list.d/contrail-local.list;\
    echo "deb [arch=amd64] http://10.84.34.201:8080/trusty/$CONTRAIL_REPO_MIRROR_SNAPSHOT/ trusty main universe" > /etc/apt/sources.list.d/trusty.list ;\
    echo "deb [arch=amd64] http://10.84.34.201:8080/trusty-updates/$CONTRAIL_REPO_MIRROR_SNAPSHOT/ trusty-updates main universe" > /etc/apt/sources.list.d/trusty-updates.list ;\
    echo "deb [arch=amd64] http://10.84.34.201:8080/trusty-security/$CONTRAIL_REPO_MIRROR_SNAPSHOT/ trusty-security main universe" > /etc/apt/sources.list.d/trusty-security.list ;\
    echo "deb [arch=all] http://10.84.34.201:8080/contrail-ansible-packages-trusty/01172017/ trusty main" > /etc/apt/sources.list.d/contrail-ansible-packages-trusty.list
RUN var1=$(echo $CONTRAIL_REPO_URL | sed -r 's#http[s]?://([[:digit:]\.]+):.*#\1#') ; \
    echo "Package: *\nPin: origin \"$var1\"\nPin-Priority: 1001" > /etc/apt/preferences
RUN echo "APT::Get::AllowUnauthenticated \"true\";" > /etc/apt/apt.conf.d/99allowunauth
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80  --recv 6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367 && \
    echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main" > /etc/apt/sources.list.d/ansible.list
RUN apt-get update -qy && \
    $apt_install $PACKAGES_ANSIBLE && \
    apt-get autoremove -yq  &&\
    rm -fr /usr/share/doc/* /usr/share/man/*
COPY entrypoint.sh /
RUN mkdir -p /etc/contrailctl/ ; chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
COPY python-contrailctl /python-contrailctl
RUN cd /python-contrailctl/; python setup.py install
ADD $CONTRAIL_ANSIBLE_TAR /
RUN contrailctl config sync -c analyticsdb -F -t package
RUN contrailctl config sync -c analyticsdb -F -t install
EXPOSE 9161 9141
