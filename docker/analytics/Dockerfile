FROM ubuntu:14.04.5
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_REPO_URL
ARG CONTRAIL_ANSIBLE_TAR
ARG ENTRY_POINT=docker_entrypoint.sh
ARG DEBIAN_FRONTEND=noninteractive
ARG apt_install="apt-get install -yq --force-yes --no-install-recommends --no-install-suggests "
ENV ANSIBLE_INVENTORY="all-in-one"
ARG PACKAGES_ANSIBLE="ansible"
RUN sed -i "1ideb $CONTRAIL_REPO_URL ./" /etc/apt/sources.list
RUN var1=$(echo $CONTRAIL_REPO_URL | sed -r 's#http[s]?://([[:digit:]\.]+):.*#\1#') ; \
    echo "Package: *\nPin: origin \"$var1\"\nPin-Priority: 1001" > /etc/apt/preferences
RUN echo "APT::Get::AllowUnauthenticated \"true\";" > /etc/apt/apt.conf.d/99allowunauth
RUN apt-get update -qy && $apt_install software-properties-common && \
    apt-add-repository -y ppa:ansible/ansible
RUN apt-get update -qy && \
    $apt_install $PACKAGES_ANSIBLE && \
    apt-get autoremove -yq  &&\
    rm -fr /usr/share/doc/* /usr/share/man/*
ADD $CONTRAIL_ANSIBLE_TAR /
RUN $apt_install python-configparser
COPY python-contrailctl /python-contrailctl
RUN cd /python-contrailctl/; python setup.py install
RUN contrailctl config sync -c analytics -F -t install
RUN mkdir -p /etc/contrailctl/
EXPOSE 8081 8086
COPY *.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh
