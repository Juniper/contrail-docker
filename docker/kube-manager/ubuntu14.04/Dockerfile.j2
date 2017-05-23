FROM contrail-base-ubuntu14.04:{{ contrail_version }}
LABEL Name=contrail-kube-manager-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=kube-manager \
      Description="Contrail kube manager" Vendor="Juniper Networks"
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
ENV CONTRAIL_ROLE kubemanager
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t package
RUN contrailctl config sync -F -v -t install
RUN rm -rf /etc/apt/sources.list.d/trusty.list
RUN rm -rf /etc/apt/sources.list.d/trusty-updates.list
RUN rm -rf /etc/apt/sources.list.d/trusty-security.list
RUN rm -rf /etc/apt/sources.list.d/contrail-ansible-packages-trusty.list
RUN rm -rf /etc/apt/sources.list.d/contrail-local.list
RUN apt-get clean; apt-get update; echo 0
