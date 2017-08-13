FROM contrail-base-ubuntu16.04:{{ contrail_version }}
LABEL Name=contrail-vcenter-plugin-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=vcenterplugin \
      Description="Contrail Vcenter Plugin" Vendor="Juniper Networks"
ENV CONTRAIL_ROLE vcenterplugin
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t package
RUN contrailctl config sync -F -v -t install
EXPOSE 8234
RUN rm -rf /etc/apt/sources.list.d/xenial.list
RUN rm -rf /etc/apt/sources.list.d/xenial-updates.list
RUN rm -rf /etc/apt/sources.list.d/xenial-security.list
RUN rm -rf /etc/apt/sources.list.d/contrail-ansible-packages-xenial.list
RUN rm -rf /etc/apt/sources.list.d/contrail-local.list
RUN apt-get clean; apt-get update; echo 0
