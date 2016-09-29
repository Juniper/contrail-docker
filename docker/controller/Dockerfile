FROM hkumar/ubuntu-14.04.2:latest
MAINTAINER Juniper Contrail <contrail@juniper.net>
ARG CONTRAIL_REPO_URL
ARG CONTRAIL_ANSIBLE_TAR
ARG ENTRY_POINT=docker_entrypoint.sh
ARG SSHPASS
ARG DEBIAN_FRONTEND=noninteractive
ARG apt_install="apt-get install -yq --force-yes --no-install-recommends --no-install-suggests "
ENV SKU=liberty
ENV ANSIBLE_INVENTORY="all-in-one"
ARG PACKAGES_INFRA="rabbitmq-server"
ARG PACKAGES_COMMON="contrail-setup contrail-utils supervisor crudini jq"
ARG PACKAGES_ANSIBLE="ansible"
RUN sed -i "1ideb $CONTRAIL_REPO_URL ./" /etc/apt/sources.list
RUN var1=$(echo $CONTRAIL_REPO_URL | sed -r 's#http[s]?://([[:digit:]\.]+):.*#\1#') ; \
    echo "Package: *\nPin: origin \"$var1\"\nPin-Priority: 1001" > /etc/apt/preferences
RUN echo; cat /etc/apt/preferences
RUN echo "APT::Get::AllowUnauthenticated \"true\";" > /etc/apt/apt.conf.d/99allowunauth
RUN $apt_install software-properties-common && \
    apt-add-repository -y ppa:ansible/ansible
RUN apt-get update -qy && \
    $apt_install $PACKAGES_COMMON && \
    $apt_install $PACKAGES_INFRA && \
    $apt_install $PACKAGES_ANSIBLE && \
    apt-get autoremove -yq  &&\
    rm -fr /usr/share/doc/* /usr/share/man/*
ADD $CONTRAIL_ANSIBLE_TAR /
RUN cd /contrail-ansible/playbooks/ && \
    ansible-playbook -i inventory/$ANSIBLE_INVENTORY -t install contrail_controller.yml
RUN $apt_install python-configparser
COPY python-contrailctl /python-contrailctl
RUN cd /python-contrailctl/; python setup.py install
VOLUME ["/var/log", "/var/crashes", "/var/lib/cassandra", "/var/lib/zookeeper"]
EXPOSE 8082 8084 8087 8088 8096 8100 5672 5997 5998 4369 8443 8444 68 123 8103 9160 2181 9092 8092 8093 8094 8101 8083 179 53 5269 8080 8143
COPY cassandra_start.sh zookeeper_start.sh /usr/local/bin/
COPY  *.sh *.j2 *.py /
COPY supervisor_configs/config/ /etc/contrail/supervisord_config_files/
COPY supervisor_configs/database/ /etc/contrail/supervisord_database_files/
RUN mkdir /etc/contrail/supervisord_files
COPY supervisor_configs/main/supervisord.conf /etc/contrail/
COPY supervisor_configs/main/*.ini /etc/contrail/supervisord_files/
COPY supervisor_configs/webui/ /etc/contrail/supervisord_webui_files/
# Workaround for now as 10240 is the maximum default fds for a container, so have to have that changed by external orchestrator
# Will be done if required
RUN sed -i '/^minfds=10240/d' /etc/contrail/supervisord_webui.conf
COPY pyj2.py /usr/local/bin/
COPY redis.conf /etc/redis/
RUN chmod +x /entrypoint.sh /usr/local/bin/pyj2.py
ENTRYPOINT /entrypoint.sh
