FROM contrail-base-ubuntu16.04:{{ contrail_version }}
LABEL Name=contrail-lb-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=lb \
      Description="Dockerimage for Contrail LB" Vendor="Juniper Networks"
ENV CONTRAIL_ROLE lb
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t install
EXPOSE 8082 5998 9696 8081
RUN rm -rf /etc/apt/sources.list.d/xenial.list
RUN rm -rf /etc/apt/sources.list.d/xenial-updates.list
RUN rm -rf /etc/apt/sources.list.d/xenial-security.list
RUN rm -rf /etc/apt/sources.list.d/contrail-ansible-packages-xenial.list
RUN rm -rf /etc/apt/sources.list.d/contrail-local.list
RUN apt-get clean; apt-get update; echo 0
