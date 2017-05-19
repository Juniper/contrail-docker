#!/usr/bin/env bash
set -x
set -e
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# configure services and start them using ansible code within contrail-ansible
contrailctl config sync -c cephcontroller -F -v

HOSTNAME=`hostname`-storage

stats_daemon_enabled=`cat /etc/contrailctl/cephcontroller.conf |grep enable_stats | grep True | wc -l`
if [ "$stats_daemon_enabled" == "1" ]; then
    /usr/bin/python /usr/bin/contrail-storage-stats --conf_file /etc/contrail/contrail-storage-nodemgr.conf &
fi

sudo -u ceph /usr/bin/ceph-mon --cluster=ceph -i $HOSTNAME -f --setuser ceph --setgroup ceph &
sudo -u ceph /usr/bin/ceph-rest-api  -c /etc/ceph/ceph.conf -n client.admin &

ceph_pid=`ps -ef|grep ceph-mon|grep -v grep|grep sudo| awk '{print $2}'`

wait "$ceph_pid"
