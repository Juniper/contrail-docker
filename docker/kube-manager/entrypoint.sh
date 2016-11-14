#!/usr/bin/env bash
set -x
source /common.sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/contrail-kube-manager
CONFIG=/etc/contrail/contrail-kubernetes.conf
SERVICE=kube-manager
ANSIBLE_INVENTORY=${ANSIBLE_INVENTORY:-"all-in-one"}

test -x $DAEMON || exit 0

DAEMON_OPTS=" -c $CONFIG $DAEMON_OPTS"


ulimit -s unlimited
ulimit -c unlimited
ulimit -d unlimited
ulimit -v unlimited
ulimit -n 4096
cd /contrail-ansible/playbooks/
ansible-playbook -i inventory/$ANSIBLE_INVENTORY -t provision,configure contrail_kube_manager.yml

$DAEMON $DAEMON_OPTS
