FROM contrail-base-ubuntu16.04:{{ contrail_version }}
LABEL Name=contrail-ceph-controller-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=ceph-controller \
      Description="Dockerimage for Contrail Ceph Controller" Vendor="Juniper Networks"
RUN contrailctl config sync -c cephcontroller -F -v -t install
EXPOSE 6789 5005 5006
RUN rm -rf /etc/apt/sources.list.d/xenial.list
RUN rm -rf /etc/apt/sources.list.d/xenial-updates.list
RUN rm -rf /etc/apt/sources.list.d/xenial-security.list
RUN rm -rf /etc/apt/sources.list.d/contrail-ansible-packages-xenial.list
RUN rm -rf /etc/apt/sources.list.d/contrail-local.list
RUN apt-get clean; apt-get update; echo 0
