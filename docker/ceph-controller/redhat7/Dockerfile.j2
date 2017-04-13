FROM contrail-base-redhat7:{{ contrail_version }}
ARG CONTRAIL_VERSION
ARG OS
LABEL Name=contrail-ceph-controller-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=ceph-controller \
      Description="Dockerimage for Contrail Ceph Controller" Vendor="Juniper Networks"

RUN contrailctl config sync -c cephcontroller -F -v -t install
EXPOSE 6789 6005 6006

# Repo cleanup
RUN [ -f /etc/yum.repos.d/contrail-install.repo ] && \
      rm -f /etc/yum.repos.d/contrail-install.repo ; \
    yum clean all ; yum clean expire-cache ;\
    echo pass
