FROM contrail-base-ubuntu14.04:{{ contrail_version }}
COPY entrypoint.sh /
LABEL Name=contrail-controller-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=controller \
      Description="Contrail Controller" Vendor="Juniper Networks"
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
ENV CONTRAIL_ROLE controller
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t package
RUN contrailctl config sync -F -v -t install
EXPOSE 8082 8084 8087 8088 8096 8100 5672 5997 5998 4369 8443 8444 68 123 8103 9160 2181 2182 9092 8092 8093 8094 8101 8083 179 53 5269 8080 8143
RUN mkdir -p /etc/contrail/supervisord_files
COPY supervisor_configs/main/supervisord.conf /etc/contrail/
COPY supervisor_configs/main/*.ini /etc/contrail/supervisord_files/
RUN rm -rf /etc/apt/sources.list.d/trusty.list
RUN rm -rf /etc/apt/sources.list.d/trusty-updates.list
RUN rm -rf /etc/apt/sources.list.d/trusty-security.list
RUN rm -rf /etc/apt/sources.list.d/contrail-ansible-packages-trusty.list
RUN rm -rf /etc/apt/sources.list.d/contrail-local.list
RUN apt-get clean; apt-get update; echo 0
