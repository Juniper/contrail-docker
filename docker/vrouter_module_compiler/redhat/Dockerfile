FROM centos:7.1.1503
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_VROUTER_SOURCE_RPM_URL
ARG ENTRY_POINT=entrypoint.sh
ARG PACKAGES="wget tar make gcc"
RUN yum install -y $PACKAGES
RUN rpm -ivh $CONTRAIL_VROUTER_SOURCE_RPM_URL
RUN cp -rf /usr/src/ /usr/src.orig/
COPY entrypoint.sh /
EXPOSE 8081 8086
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
