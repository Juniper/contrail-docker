#!/usr/bin/env bash

temp=`mktemp -d`
component=$1
package_url=${2:-http://nodei16/contrail-install-packages_3.0.2.0-35~liberty_all.deb}
image_path=${3:-/cs-shared/images/docker-images/contrail/}
if [[ $package_url =~ (ssh|http|https)*://.*/contrail-install-packages_[0-9\.\-]+~[a-zA-Z]+_all.deb ]]; then
    contrail_version=`echo ${package_url##*/} | sed 's/contrail-install-packages_\([0-9\.\-]*\).*/\1/'`
    openstack_release=`echo ${package_url##*/} | sed 's/contrail-install-packages_[0-9\.\-]*~\([a-zA-Z]*\).*/\1/'`
else
    echo -e "Not able to extract contrail-version and SKU from contrail package url\nBad contrail package url, it should match regex http[s]*://.*/contrail-install-packages_[0-9\.\-]+~[a-zA-Z]+_all.deb"
    exit 1
fi
cp -r common.sh $component/* $temp
cd $temp
docker build  --build-arg CONTRAIL_INSTALL_PACKAGE_URL=$package_url -t contrail-${component}-${openstack_release}:${contrail_version} .; rv=$?
if [[ $rv == 0 ]]; then
    docker save contrail-${component}-${openstack_release}:${contrail_version} | gzip -c > ${image_path}/contrail-${component}-${openstack_release}-${contrail_version}.tar.gz
else
    echo "Docker build failed"
fi