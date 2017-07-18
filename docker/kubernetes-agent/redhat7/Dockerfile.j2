FROM contrail-base-redhat7:{{ contrail_version }}
COPY entrypoint.sh /
ARG CONTRAIL_VERSION
ARG OS
LABEL Name=contrail-kubernetes-agent-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=kubernetesagent \
      Description="Dockerimage for Contrail Kubernetes Agent" Vendor="Juniper Networks"
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
ENV CONTRAIL_ROLE kubernetesagent
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t package
RUN contrailctl config sync -F -v -t install

# Repo cleanup
RUN [ -f /etc/yum.repos.d/contrail-install.repo ] && \
      rm -f /etc/yum.repos.d/contrail-install.repo ; \
    yum clean all ; yum clean expire-cache ;\
    echo pass
