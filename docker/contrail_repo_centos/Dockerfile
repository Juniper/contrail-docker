FROM centos:7.1.1503
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_INSTALL_PACKAGE_TAR_URL
ARG http_proxy
ARG https_proxy
ARG SSHPASS
ARG SSHUSER=root
ARG PACKAGES_CONTRAIL_REPO="nginx createrepo"

COPY install_repo.sh /
RUN bash -x /install_repo.sh
COPY nginx_site.conf /etc/nginx/nginx.conf
RUN echo "server_names_hash_bucket_size 64;" > /etc/nginx/conf.d/server_names_hash_bucket_size.conf
RUN echo "echo \"Repo is up on port 2567, point apt source.list to 'deb http://<ip of repo>:2567 ./'\"; /usr/sbin/nginx" > /entrypoint.sh; \
    chmod +x /entrypoint.sh
EXPOSE 2567
ENTRYPOINT /entrypoint.sh
