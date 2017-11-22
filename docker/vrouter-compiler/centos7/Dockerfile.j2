FROM contrail-base-centos7:{{ contrail_version }}
MAINTAINER Juniper Contrail <contrail@juniper.net>
LABEL Name=contrail-vrouter-compiler-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=vrouter-compiler \
      Description="Contrail vrouter compiler" Vendor="Juniper Networks"
ARG CONTRAIL_REPO_URL
ARG CONTRAIL_ANSIBLE_TAR
ARG CONTRAIL_VERSION
ARG OS=centos7
ENV CONTRAIL_VERSION $CONTRAIL_VERSION
ENV OS=$OS
ARG PACKAGES="contrail-vrouter-source"
RUN yum clean all && \
    yum clean expire-cache && \
    yum repolist
RUN yum install -y $PACKAGES
ARG MAKE_PACKAGE="make"
RUN yum install -y $MAKE_PACKAGE
COPY entrypoint.sh /
EXPOSE 8081 8086
RUN cp -rf /usr/src/ /usr/src.orig/
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
