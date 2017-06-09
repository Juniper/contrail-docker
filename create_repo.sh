#!/usr/bin/env bash
## Script to create yum/deb repo for a given list of TGZs

set -x

function xtrace_status () {
  set | grep -q SHELLOPTS=.*:xtrace
  return $?
}

function ssh_download () {
    # convert space seperated args into variables
    eval ${@// /;}

    tgz_file_name=${tgz_file_path##*/}
    export sshuser=${sshuser:-root}
    export SSHPASS=${sshpass:-passwd}
    if [[ -z $tgz_file_path ]]; then
        echo "ERROR: Empty TGZ path @ ssh_download"
        return 1
    fi

    server=$(echo $tgz_file_path | sed 's/ssh:\/\///;s|\/.*||')
    path=$(echo $tgz_file_path | sed -r 's#ssh://[a-zA-Z0-9_\.\-]+##')
    [[ xtrace_status ]] && set +x
    sshpass -e scp \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            ${sshuser}@${server}:${path} ${dest_file_path}
    if [ $? != 0 ]; then
        echo "ERROR: Download ( $tgz_file_path ) failed using sshpass"
        return 1
    fi
    set -x
}

# Required Args:
# tgz_file_path - Http file path of TGZ
# dest_file_path - Download destination
#
function wget_download () {
    # convert space seperated args into variables
    eval ${@// /;}

    if [[ -z $tgz_file_path ]] || [[ -z $dest_file_path ]]; then
        echo "ERROR: One or more required params are missing"
        echo "ERROR: Required Args: tgz_file_path=($tgz_file_path) dest_file_path=($dest_file_path)"
    fi
    wget $tgz_file_path -O $dest_file_path
    if [ $? != 0 ]; then
        echo "ERROR: Download ( $tgz_file_path ) to ( $dest_file_path ) failed using wget"
        return 1
    fi
}

function create_yum_repo () {
    # convert space seperated args into variables
    eval ${@// /;}

    repo_name=$repo_dir
    createrepo $repo_name
}

function create_deb_repo () {
    # convert space seperated args into variables
    eval ${@// /;}

    repo_name=$repo_dir
    (cd $repo_name && dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz)
}

function get_repo_type () {
    # convert space seperated args into variables
    eval ${@// /;}

    repo_dir=$(readlink -f $repo_dir)
    if [ ! -r $repo_dir ]; then
        echo "ERROR: Repo Dir ( $repo_dir ) is not accessible"
        return 1
    fi
    rpms=$(ls -1 $repo_dir/*.rpm 2>/dev/null | wc -l)
    debs=$(ls -1 $repo_dir/*.deb 2>/dev/null | wc -l)
    if ( [[ $rpms != 0 ]] && [[ $debs != 0 ]] ) || \
       ( [[ $rpms == 0 ]] && [[ $debs == 0 ]] ); then
        echo "ERROR: deb and rpms are mixed or none found; Unsupported Repo type"
        return 1
    fi
    [ $rpms != 0 ] && echo yum
    [ $debs != 0 ] && echo deb
}

# Required Args:
# tgz_files
# repo_dir
#
function create_repo () {
    # convert space seperated args into variables
    eval ${@// /;}

    tgz_file_paths=$tgz_files
    repo_name=$repo_dir
    for tgz_file_path in $tgz_file_paths; do
        tgz_file_name=${tgz_file_path##*/}
        tempdir=$(mktemp -d)
        dest_file_path=${tempdir}/${tgz_file_name}
        if [[ $tgz_file_path =~ ^http[s]*:// ]]; then
            wget_download tgz_file_path=$tgz_file_path dest_file_path=$dest_file_path
        elif [[ $tgz_file_path =~ ^ssh:// ]]; then
            ssh_download tgz_file_path=$tgz_file_path dest_file_path=$tempdir/${tgz_file_name} \
                         sshpass=$sshpass sshuser=$sshuser
        else
            echo "ERROR, Unknown url format, only http[s], ssh supported"
            return 1
        fi
        tar -xzf $dest_file_path -C $repo_name
        if [ $? != 0 ]; then
            echo "ERROR: Untar ( $dest_file_path ) failed"
            return 1
        fi
        rm -rf ${tempdir}
        repo_type=$(get_repo_type repo_dir=$repo_name)
        if [ "$repo_type" == "yum" ]; then
            create_yum_repo repo_dir=$repo_name
        elif [ "$repo_type" == "deb" ]; then
            create_deb_repo repo_dir=$repo_name
        else
            echo "ERROR: Unknown Repo Type: %s" % repo_type
            return 1
        fi

        if [ $? != 0 ]; then
            echo "ERROR: create_repo at ( ${repo_name} ) failed"
            return 1
        fi
    done
}

# Required Args
# repo_dir
# package_urls
#
function create_pkg_repo() {
    # convert space seperated args into variables
    eval ${@// /;}

    if [[ -z $package_urls ]] || [[ -z $repo_dir ]]; then
        echo "ERROR: One or more required params are missing"
        echo "ERROR: Required Args: package_urls=($package_urls) repo_dir=($repo_dir)"
        exit 1
    fi

    package_urls=$(echo $package_urls | tr "," " ")
    create_repo tgz_files=$package_urls repo_dir=$repo_dir && echo "Repo Created Successfully"
}
