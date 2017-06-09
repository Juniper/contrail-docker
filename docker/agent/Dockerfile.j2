FROM contrail-base-centos7:{{ contrail_version }}
ARG CONTRAIL_VERSION
ARG OS
LABEL Name=contrail-agent-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=agent \
      Description="Dockerimage for Contrail Vrouter Agent" Vendor="Juniper Networks"
ENV CONTRAIL_ROLE agent
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t package
RUN contrailctl config sync -F -v -t install
EXPOSE 8085 9090

# Repo cleanup
RUN [ -f /etc/yum.repos.d/contrail-install.repo ] && \
      rm -f /etc/yum.repos.d/contrail-install.repo ; \
    yum clean all ; yum clean expire-cache ;\
    echo pass
