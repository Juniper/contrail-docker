FROM hkumar/ubuntu-14.04.2:latest
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_INSTALL_PACKAGE_URL
ARG ENTRY_POINT=docker_entrypoint.sh
ARG SSHPASS
ARG DEBIAN_FRONTEND=noninteractive
ENV SKU=liberty
ARG PACKAGES_CONTRAIL_REPO="nginx"

RUN wget -q --spider $CONTRAIL_INSTALL_PACKAGE_URL

RUN wget $CONTRAIL_INSTALL_PACKAGE_URL -O /contrail-install-packages.deb && \
    dpkg -i /contrail-install-packages.deb && \
    rm -f /contrail-install-packages.deb && \
    cd /opt/contrail/contrail_packages/ && ./setup.sh
RUN apt-get install -y --force-yes $PACKAGES_CONTRAIL_REPO;
COPY nginx_site.conf /etc/nginx/sites-enabled/default
RUN echo "server_names_hash_bucket_size 64;" > /etc/nginx/conf.d/server_names_hash_bucket_size.conf
RUN sed -i '1idaemon off;' /etc/nginx/nginx.conf
RUN echo "echo \"Repo is up on port 1567, point apt source.list to 'deb http://<ip of repo>:1567 ./'\"; /usr/sbin/nginx" > /entrypoint.sh; \
    chmod +x /entrypoint.sh
EXPOSE 1567
ENTRYPOINT /entrypoint.sh