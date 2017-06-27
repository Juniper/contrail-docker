FROM contrail-base-centos7:{{ contrail_version }}
ARG CONTRAIL_VERSION
ARG OS
LABEL Name=contrail-controller-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=controller \
      Description="Dockerimage for Contrail Controller" Vendor="Juniper Networks"
ENV CONTRAIL_ROLE controller
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t package
RUN contrailctl config sync -F -v -t install

EXPOSE 53 68 123 179 2181 4369 \
       5269 5672 5997 5998 \
       8080 8082 8083 8084 8087 8088 8092 8093 8094 8096 8100 8101 8103 8143 8443 8444 \
       9092 9160

# Copy Supervisor configs
COPY supervisor_configs/config/ /etc/contrail/supervisord_config_files/
RUN mkdir -p /etc/contrail/supervisord_files
COPY supervisor_configs/main/supervisord.conf /etc/contrail/
COPY supervisor_configs/main/*.ini /etc/contrail/supervisord_files/

# Repo cleanup
RUN [ -f /etc/yum.repos.d/contrail-install.repo ] && \
      rm -f /etc/yum.repos.d/contrail-install.repo ; \
    yum clean all ; yum clean expire-cache ;\
    echo pass
