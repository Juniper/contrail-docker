#!/usr/bin/env bash

package_url=${CONTRAIL_INSTALL_PACKAGE_URL}
testbed=${TESTBED}

if [[ $package_url =~ (ssh|http|https)*://.*/contrail-install-packages_[0-9\.\-]+~[a-zA-Z]+_all.deb ]]; then
        contrail_version=`echo ${CONTRAIL_INSTALL_PACKAGE_URL##*/} | sed 's/contrail-install-packages_\([0-9\.\-]*\).*/\1/'`
        openstack_release=`echo ${CONTRAIL_INSTALL_PACKAGE_URL##*/} | sed 's/contrail-install-packages_[0-9\.\-]*~\([a-zA-Z]*\).*/\1/'`
else
    echo -e "Not able to extract contrail-version and SKU from contrail package url\nBad contrail package url, it should match regex http[s]*://.*/contrail-install-packages_[0-9\.\-]+~[a-zA-Z]+_all.deb\nSet the variable \$CONTRAIL_INSTALL_PACKAGE_URL."
    exit 1
fi

if [[ ! -f $testbed ]]; then
    echo "Invalid testbed file provided - set the environment variable \$TESTBED with valid local path"
fi

if [[ ! -f /etc/hostname ]]; then
    echo `hostname` > /etc/hostname
fi

wget -O /tmp/contrail-install-package.deb $package_url
dpkg -i /tmp/contrail-install-package.deb
cd /opt/contrail/contrail_packages
bash setup.sh
cp -fv $testbed /opt/contrail/utils/fabfile/testbeds/testbed.py


