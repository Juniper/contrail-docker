#!/usr/bin/env bash

set -x
function fail() {
    echo "$@"
    exit 1
}

KERNEL_VERSION=$(uname -r)
VROUTER_VERSION=$(rpm -q contrail-vrouter-source | sed -r 's/contrail-vrouter-source-([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\-[[:digit:]]+).*/\1/')
if [[ $INSTALL_VROUTER_MODULE ]]; then
    VROUTER_MODULE_SAVE_PATH="/lib/modules/${KERNEL_VERSION}/kernel/net/contrail/"
else
    VROUTER_MODULE_PATH=${VROUTER_MODULE_PATH:-"/opt/contrail/vrouter_modules/"}
    VROUTER_MODULE_SAVE_PATH=${VROUTER_MODULE_PATH}/${KERNEL_VERSION}/${VROUTER_VERSION}
fi
if [[ ! -e /lib/modules/${KERNEL_VERSION} ]]; then
    fail "No kernel module directory found under /lib/modules for current kernel ($KERNEL_VERSION)"
fi

if [[ ! -e /usr/src/kernels/$KERNEL_VERSION ]]; then
    fail "No kernel build directory found under /usr/src/kernels/ for current kernel ($KERNEL_VERSION)"
fi

cd /usr/src/modules/contrail-vrouter/
tar zxvf contrail-vrouter*.tar.gz
make
[[ -e $VROUTER_MODULE_SAVE_PATH ]] || mkdir -p $VROUTER_MODULE_SAVE_PATH
cp vrouter.ko $VROUTER_MODULE_SAVE_PATH || fail "Failed copying vrouter module to $VROUTER_MODULE_SAVE_PATH"
echo "Vrouter kernel module is copied to $VROUTER_MODULE_SAVE_PATH"
