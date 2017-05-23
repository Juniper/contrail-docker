FROM contrail-base-ubuntu14.04:{{ contrail_version }}
COPY entrypoint.sh /
LABEL Name=contrail-analytics-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=analytics \
      Description="Contrail Analytics" Vendor="Juniper Networks"
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
ENV CONTRAIL_ROLE analytics
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t package
RUN contrailctl config sync -F -v -t install
EXPOSE 8081 8086
RUN rm -rf /etc/apt/sources.list.d/trusty.list
RUN rm -rf /etc/apt/sources.list.d/trusty-updates.list
RUN rm -rf /etc/apt/sources.list.d/trusty-security.list
RUN rm -rf /etc/apt/sources.list.d/contrail-ansible-packages-trusty.list
RUN rm -rf /etc/apt/sources.list.d/contrail-local.list
RUN apt-get clean; apt-get update; echo 0
