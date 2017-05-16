FROM 10.84.34.155:5000/contrail-base-os-images-ubuntu:16.04.2
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_REPO_URL
ARG CONTRAIL_ANSIBLE_TAR
ARG http_proxy
ARG https_proxy
ARG no_proxy
ARG OS=ubuntu16.04
ARG CONTRAIL_VERSION
ENV CONTRAIL_VERSION $CONTRAIL_VERSION
ENV OS=$OS
ARG DEBIAN_FRONTEND=noninteractive
ARG apt_install="apt-get install -yq --force-yes --no-install-recommends --no-install-suggests "
ENV ANSIBLE_INVENTORY="all-in-one"
ARG PACKAGES_ANSIBLE="ansible iproute2 python-configparser vim ssh-client iputils-ping less sudo"
ARG CONTRAIL_REPO_MIRROR_SNAPSHOT=04042017
COPY contrail-ubuntu-mirror.key /
RUN apt-key add /contrail-ubuntu-mirror.key;\
    echo > /etc/apt/sources.list ;\
    echo "deb $CONTRAIL_REPO_URL ./" > /etc/apt/sources.list.d/contrail-local.list;\
    echo "deb [arch=amd64] http://10.84.34.201:8080/xenial/$CONTRAIL_REPO_MIRROR_SNAPSHOT/ xenial main universe" > /etc/apt/sources.list.d/xenial.list ;\
    echo "deb [arch=amd64] http://10.84.34.201:8080/xenial-updates/$CONTRAIL_REPO_MIRROR_SNAPSHOT/ xenial-updates main universe" > /etc/apt/sources.list.d/xenial-updates.list ;\
    echo "deb [arch=amd64] http://10.84.34.201:8080/xenial-security/$CONTRAIL_REPO_MIRROR_SNAPSHOT/ xenial-security main universe" > /etc/apt/sources.list.d/xenial-security.list ;\
    echo "deb [arch=all]  http://10.84.34.201:8080/contrail-ansible-packages-xenial/01172017/ xenial main" > /etc/apt/sources.list.d/contrail-ansible-packages-xenial.list
RUN var1=$(echo $CONTRAIL_REPO_URL | sed -r 's#http[s]?://([[:digit:]\.]+):.*#\1#') ; \
    echo "Package: *\nPin: origin \"$var1\"\nPin-Priority: 1001" > /etc/apt/preferences
RUN echo "APT::Get::AllowUnauthenticated \"true\";" > /etc/apt/apt.conf.d/99allowunauth
RUN apt-get update -qy && \
    $apt_install $PACKAGES_ANSIBLE && \
    apt-get autoremove -yq  &&\
    rm -fr /usr/share/doc/* /usr/share/man/*
RUN cd /lib/systemd/system/sysinit.target.wants/; ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1 \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*; \
rm -f /lib/systemd/system/plymouth*; \
rm -f /lib/systemd/system/systemd-update-utmp*;
RUN systemctl set-default multi-user.target
ENV init /lib/systemd/systemd
COPY python-contrailctl /python-contrailctl
RUN cd /python-contrailctl/; python setup.py install
ADD $CONTRAIL_ANSIBLE_TAR /
ENTRYPOINT ["/lib/systemd/systemd"]
CMD ["systemd.unit=multi-user.target"]
