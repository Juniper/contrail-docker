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

yum_install="yum install -y "
$yum_install epel-release

if [[ -z $CONTRAIL_INSTALL_PACKAGE_TAR_URL ]]; then
    echo "ERROR CONTRAIL_INSTALL_PACKAGE_TAR_URL undefined"
    exit 1
fi

if [[ $CONTRAIL_INSTALL_PACKAGE_TAR_URL =~ ^http[s]*:// ]]; then
    $yum_install wget tar
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
    $yum_install sshpass openssh-clients tar
    sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${SSHUSER}@${server}:${path} /tmp/contrail-install-packages.tar.gz
else
    echo "ERROR, Unknown url format, only http[s], ssh supported"
    exit 1
fi

mkdir -p /opt/contrail/contrail_install_repo
cd /opt/contrail/contrail_install_repo
tar zxf /tmp/contrail-install-packages.tar.gz
rm -f /tmp/contrail-install-packages.tar.gz
$yum_install $PACKAGES_CONTRAIL_REPO
createrepo -v /opt/contrail/contrail_install_repo
