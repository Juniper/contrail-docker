#!/usr/bin/env bash

set -e
function try_wget () {
    wget -q --spider $1;
    return $?
}

xtrace_status() {
  set | grep -q SHELLOPTS=.*:xtrace
  return $?
}

apt_install="apt-get install -yq --force-yes --no-install-recommends --no-install-suggests "
apt_update="apt-get update -qy"

if [[ -z $CONTRAIL_INSTALL_PACKAGE_TAR_URL ]]; then
    echo "ERROR CONTRAIL_INSTALL_PACKAGE_TAR_URL undefined"
    exit 1
fi

if [[ $CONTRAIL_INSTALL_PACKAGE_TAR_URL =~ ^http[s]*:// ]]; then
    $apt_update; $apt_install wget
    if try_wget $CONTRAIL_INSTALL_PACKAGE_TAR_URL; then
       wget -q $CONTRAIL_INSTALL_PACKAGE_TAR_URL -O /tmp/contrail-install-packages.tar.gz
    else
        echo "ERROR! $CONTRAIL_INSTALL_PACKAGE_TAR_URL is not accessible"
        exit 1
    fi
elif [[ $CONTRAIL_INSTALL_PACKAGE_TAR_URL =~ ^ssh:// ]]; then
    server=` echo $CONTRAIL_INSTALL_PACKAGE_TAR_URL | sed 's/ssh:\/\///;s|\/.*||'`
    path=`echo $CONTRAIL_INSTALL_PACKAGE_TAR_URL |sed -r 's#ssh://[a-zA-Z0-9_\.\-]+##'`
    export SSHUSER=${SSHUSER:-root}
    if xtrace_status; then
        set +x
        xtrace=1
    fi
    export SSHPASS=${SSHPASS:-passwd}
    [[ -n $xtrace ]] && set -x
    $apt_update; $apt_install sshpass openssh-client
    sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${SSHUSER}@${server}:${path} /tmp/contrail-install-packages.tar.gz
else
    echo "ERROR, Unknown url format, only http[s], ssh supported"
    exit 1
fi

mkdir -p /opt/contrail/contrail_install_repo
cd /opt/contrail/contrail_install_repo
tar zxf /tmp/contrail-install-packages.tar.gz
rm -f /tmp/contrail-install-packages.tar.gz
$apt_install $PACKAGES_CONTRAIL_REPO dpkg-dev
cd /opt/contrail/contrail_install_repo/
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
apt-get purge -yq dpkg-dev sshpass wget || true
apt-get autoremove -yq
apt-get clean -yq
rm -fr /var/lib/apt/lists/* /usr/share/doc/* /usr/share/man/*
