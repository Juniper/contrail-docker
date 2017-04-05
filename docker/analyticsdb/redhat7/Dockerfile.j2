FROM contrail-base-redhat7:{{ contrail_version }}
ARG CONTRAIL_VERSION
ARG OS
LABEL Name=contrail-analyticsdb-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=analyticsdb \
      Description="Dockerimage for Contrail AnalyticsDB" Vendor="Juniper Networks"
ENV CONTRAIL_ROLE analyticsdb
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t package
RUN contrailctl config sync -F -v -t install
EXPOSE 9141 9161

# Repo cleanup
RUN [ -f /etc/yum.repos.d/contrail-install.repo ] && \
      rm -f /etc/yum.repos.d/contrail-install.repo ; \
    yum clean all ; yum clean expire-cache ;\
    echo pass

