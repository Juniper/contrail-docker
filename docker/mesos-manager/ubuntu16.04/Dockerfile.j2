FROM contrail-base-ubuntu16.04:{{ contrail_version }}
LABEL Name=contrail-mesos-manager-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=mesos-manager \
      Description="Contrail Mesos Manager" Vendor="Juniper Networks"
ENV CONTRAIL_ROLE mesosmanager
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t install
RUN rm -rf /etc/apt/sources.list.d/xenial.list
RUN rm -rf /etc/apt/sources.list.d/xenial-updates.list
RUN rm -rf /etc/apt/sources.list.d/xenial-security.list
RUN rm -rf /etc/apt/sources.list.d/contrail-ansible-packages-xenial.list
RUN rm -rf /etc/apt/sources.list.d/contrail-local.list
RUN apt-get clean; apt-get update; echo 0
