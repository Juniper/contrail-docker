FROM 10.84.34.155:5000/contrail-base-os-images-centos7:7.3
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_INSTALL_PACKAGE_TAR_URL
ARG CONTRAIL_REPO_PORT
ARG CONTRAIL_REPO_DIR
ARG CONTRAIL_VERSION
ARG OS
ARG SSHPASS
ARG SSHUSER=root
LABEL Name=contrail-repo-$OS \
      Version="$CONTRAIL_VERSION" \
      Description="Dockerimage for Contrail Repo" Vendor="Juniper Networks"

RUN mkdir -p /opt/contrail/contrail_install_repo
COPY $CONTRAIL_REPO_DIR /opt/contrail/contrail_install_repo/
RUN echo "echo \"Repo is up on port $CONTRAIL_REPO_PORT, Create repo file with baseurl=http://<ip of repo>:$CONTRAIL_REPO_PORT \"; cd /opt/contrail/contrail_install_repo && python -m SimpleHTTPServer $CONTRAIL_REPO_PORT" > /entrypoint.sh; \
    chmod +x /entrypoint.sh
EXPOSE $CONTRAIL_REPO_PORT
ENTRYPOINT /entrypoint.sh
