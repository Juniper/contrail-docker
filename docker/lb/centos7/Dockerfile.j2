FROM contrail-base-centos7:{{ contrail_version }}
ARG CONTRAIL_VERSION
ARG OS
LABEL Name=contrail-lb-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=lb \
      Description="Dockerimage for Contrail LB" Vendor="Juniper Networks"
ENV CONTRAIL_ROLE lb
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t install
EXPOSE 5998 8081 8082 9696

# Repo cleanup
RUN [ -f /etc/yum.repos.d/contrail-install.repo ] && \
      rm -f /etc/yum.repos.d/contrail-install.repo ; \
    yum clean all ; yum clean expire-cache ;\
    echo pass
