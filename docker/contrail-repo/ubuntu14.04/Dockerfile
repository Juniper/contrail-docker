FROM 10.84.34.155:5000/ubuntu:14.04.5
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_INSTALL_PACKAGE_TAR_URL
ARG http_proxy
ARG https_proxy
ARG OS=ubuntu14.04
ARG CONTRAIL_VERSION
ARG SSHPASS
ARG SSHUSER=root
ARG DEBIAN_FRONTEND=noninteractive
ARG PACKAGES_CONTRAIL_REPO="nginx"
LABEL Name=contrail-repo-$OS \
      Version="$CONTRAIL_VERSION" \
      Description="Contrail Repo" Vendor="Juniper Networks"
COPY install_repo.sh /
RUN bash -x /install_repo.sh
COPY nginx_site.conf /etc/nginx/sites-enabled/default
RUN echo "server_names_hash_bucket_size 64;" > /etc/nginx/conf.d/server_names_hash_bucket_size.conf
RUN sed -i '1idaemon off;' /etc/nginx/nginx.conf
RUN echo "echo \"Repo is up on port 1567, point apt source.list to 'deb http://<ip of repo>:1567 ./'\"; /usr/sbin/nginx" > /entrypoint.sh; \
    chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
