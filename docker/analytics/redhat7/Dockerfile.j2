FROM contrail-base-redhat7:{{ contrail_version }}
ARG CONTRAIL_VERSION
ARG OS
LABEL Name=contrail-analytics-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=analytics \
      Description="Dockerimage for Contrail Analytics" Vendor="Juniper Networks"
ENV CONTRAIL_ROLE analytics
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t package
RUN contrailctl config sync -F -v -t install
EXPOSE 8081 8086

# Repo cleanup
RUN [ -f /etc/yum.repos.d/contrail-install.repo ] && \
      rm -f /etc/yum.repos.d/contrail-install.repo ; \
    yum clean all ; yum clean expire-cache ;\
    echo pass

