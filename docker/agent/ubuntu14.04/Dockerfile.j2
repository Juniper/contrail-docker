FROM contrail-base-ubuntu14.04:{{ contrail_version }}
COPY entrypoint.sh /
LABEL Name=contrail-agent-$OS \
      Version="$CONTRAIL_VERSION" \
      contrail.role=agent \
      Description="Contrail Vrouter Agent" Vendor="Juniper Networks"
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
ENV CONTRAIL_ROLE agent
RUN echo $CONTRAIL_ROLE > /etc/contrail-role
RUN contrailctl config sync -F -v -t package
RUN contrailctl config sync -F -v -t install
EXPOSE 8085 9090
RUN cp -rf /usr/src/ /usr/src.orig/
RUN rm -rf /etc/apt/sources.list.d/trusty.list
RUN rm -rf /etc/apt/sources.list.d/trusty-updates.list
RUN rm -rf /etc/apt/sources.list.d/trusty-security.list
RUN rm -rf /etc/apt/sources.list.d/contrail-ansible-packages-trusty.list
RUN rm -rf /etc/apt/sources.list.d/contrail-local.list
RUN apt-get clean; apt-get update; echo 0
