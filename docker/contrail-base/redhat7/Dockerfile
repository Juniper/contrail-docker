FROM 10.84.34.155:5000/contrail-base-os-images-rhel7:7.4
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_REPO_URL
ARG CONTRAIL_ANSIBLE_TAR
ARG CONTRAIL_VERSION
ARG OS
ENV ANSIBLE_INVENTORY="all-in-one"
ARG ANSIBLE_PACKAGES="ansible"
LABEL Name=contrail-base-$OS \
      Version="$CONTRAIL_VERSION" \
      Description="Base Docker Image for Contrail" Vendor="Juniper Networks"

# Contrail Install Repo; This repo file will removed after contrail
# installation at the app containers
COPY contrail-install.repo /etc/yum.repos.d/contrail-install.repo

# Copy required files to Docker
COPY python-contrailctl /python-contrailctl

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

RUN echo $CONTRAIL_REPO_URL && \
    sed -i "s#baseurl=baseurl#baseurl=$CONTRAIL_REPO_URL#" /etc/yum.repos.d/contrail-install.repo && \
    yum clean all && yum clean expire-cache && \
    yum repolist
RUN yum -y install \
      yum-plugin-priorities python-setuptools $ANSIBLE_PACKAGES \
      iproute net-tools openssh-clients wget tar telnet vim which initscripts \
      sudo kexec-tools less file gcc make python-devel python-setuptools \
      libyaml-devel openssl-devel libtool libffi-devel;

RUN cd /python-contrailctl/; python setup.py install
ADD $CONTRAIL_ANSIBLE_TAR /
RUN systemctl set-default multi-user.target
ENV init /lib/systemd/systemd
ENTRYPOINT ["/lib/systemd/systemd"]
CMD ["systemd.unit=multi-user.target"]

RUN yum clean all ; yum clean expire-cache; echo pass
