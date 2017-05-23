FROM contrail-base-ubuntu14.04:{{ contrail_version }}
LABEL Name=contrail-lb-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=lb \
      Description="Contrail LB" Vendor="Juniper Networks"
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
ENV CONTRAIL_ROLE lb
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t install
EXPOSE 8082 5998 9696 8081
RUN rm -rf /etc/apt/sources.list.d/trusty.list
RUN rm -rf /etc/apt/sources.list.d/trusty-updates.list
RUN rm -rf /etc/apt/sources.list.d/trusty-security.list
RUN rm -rf /etc/apt/sources.list.d/contrail-ansible-packages-trusty.list
RUN rm -rf /etc/apt/sources.list.d/contrail-local.list
RUN apt-get clean; apt-get update; echo 0
