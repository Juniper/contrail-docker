FROM centos:7.1.1503
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_REPO_URL
ARG CONTRAIL_ANSIBLE_TAR
ARG ENTRY_POINT=entrypoint.sh
ARG PACKAGES="wget tar make gcc contrail-vrouter-source"
RUN echo -e "[contrail-repo]\nname=Contrail Repository\nbaseurl=$CONTRAIL_REPO_URL\ngpgcheck=0\nenabled=1" > /etc/yum.repos.d/contrail.repo
RUN yum clean all && \
    yum install -y $PACKAGES
RUN cp -rf /usr/src/ /usr/src.orig/
COPY entrypoint.sh /
EXPOSE 8081 8086
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
