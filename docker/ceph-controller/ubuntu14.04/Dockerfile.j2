FROM contrail-base-ubuntu14.04:{{ contrail_version }}
LABEL Name=contrail-ceph-controller-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=ceph-controller \
      Description="Dockerimage for Contrail Ceph Controller" Vendor="Juniper Networks"
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
ENV CONTRAIL_ROLE cephcontroller
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t install
EXPOSE 6789 5005 5006
RUN rm -rf /etc/apt/sources.list.d/trusty.list
RUN rm -rf /etc/apt/sources.list.d/trusty-updates.list
RUN rm -rf /etc/apt/sources.list.d/trusty-security.list
RUN rm -rf /etc/apt/sources.list.d/contrail-ansible-packages-trusty.list
RUN rm -rf /etc/apt/sources.list.d/contrail-local.list
RUN apt-get clean; apt-get update; echo 0
