#!/usr/bin/env bash
## Script to create yum repo for a given list of TGZs

set -x

function xtrace_status () {
  set | grep -q SHELLOPTS=.*:xtrace
  return $?
}

function ssh_download () {
    tgz_file_path=$1
    dest_file_path=$2
    tgz_file_name=${tgz_file_path##*/}
    export SSHUSER=${SSHUSER:-root}
    export SSHPASS=${SSHPASS:-passwd}
    if [[ -z $tgz_file_path ]]; then
        echo "ERROR: Empty TGZ path @ ssh_download"
        exit 1
    fi

    server=$(echo $tgz_file_path | sed 's/ssh:\/\///;s|\/.*||')
    path=$(echo $tgz_file_path | sed -r 's#ssh://[a-zA-Z0-9_\.\-]+##')
    [[ xtrace_status ]] && set +x
    sshpass -e scp \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            ${SSHUSER}@${server}:${path} ${dest_file_path}
    if [ $? != 0 ]; then
        echo "ERROR: Download ( $tgz_file_path ) failed using sshpass"
        exit 1
    fi
    set -x
}

function wget_download () {
    tgz_file_path=$1
    dest_file_path=$2
    wget $tgz_file_path -O ${tempdir}/${tgz_file_name}
    if [ $? != 0 ]; then
        echo "ERROR: Download ( $tgz_file_path ) failed using wget"
        exit 1
    fi
}

function create_yum_repo () {
    tgz_file_path=$1
    tgz_file_name=${tgz_file_path##*/}
    repo_name=/opt/contrail/contrail_install_repo
    tempdir=$(mktemp -d)
    if [[ $tgz_file_path =~ ^http[s]*:// ]]; then
        wget_download $tgz_file_path ${tempdir}/${tgz_file_name}
    elif [[ $tgz_file_path =~ ^ssh:// ]]; then
        ssh_download $tgz_file_path $tempdir/${tgz_file_name}
    else
        echo "ERROR, Unknown url format, only http[s], ssh supported"
        exit 1
    fi
    mkdir -p $repo_name
    tar -xzf ${tempdir}/${tgz_file_name} -C $repo_name
    if [ $? != 0 ]; then
        echo "ERROR: Untar ( ${tempdir}/${tgz_file_name} ) failed"
        exit 1
    fi
    rm -rf ${tempdir}
    createrepo $repo_name
    if [ $? != 0 ]; then
        echo "ERROR: createrepo at ( ${repo_name} ) failed"
        exit 1
    fi
}

## Main

if [[ -z $CONTRAIL_INSTALL_PACKAGE_TAR_URL ]]; then
    echo "ERROR CONTRAIL_INSTALL_PACKAGE_TAR_URL undefined"
    exit 1
else
    CONTRAIL_INSTALL_PACKAGE_TAR_URL=$(echo $CONTRAIL_INSTALL_PACKAGE_TAR_URL | tr "," " ")
fi

for each in $CONTRAIL_INSTALL_PACKAGE_TAR_URL; do
    create_yum_repo $each
    if [ $? == 0 ]; then
        echo "Successfully created repo for ( $each )"
    else
        echo "ERROR: Repo creation for ( $each ) failed"
        exit 1
    fi
done
