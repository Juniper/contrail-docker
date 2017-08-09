FROM contrail-base-redhat7:{{ contrail_version }}
ARG CONTRAIL_VERSION
ARG OS
LABEL Name=contrail-kube-manager-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=kube-manager \
      Description="Contrail Kube manager" Vendor="Juniper Networks"
ENV CONTRAIL_ROLE kubemanager
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t package
RUN contrailctl config sync -F -v -t install
EXPOSE 8108

# Repo cleanup
RUN [ -f /etc/yum.repos.d/contrail-install.repo ] && \
      rm -f /etc/yum.repos.d/contrail-install.repo ; \
    yum clean all ; yum clean expire-cache ;\
    echo pass
