#!/usr/bin/env bash
set -x

# Args:
# contrail_version
# tar_name
#
function create_kolla_container_tar {
    eval $1
    if [[ -z $contrail_version ]] || [[ -z $tar_name ]]; then
        echo "ERROR: One or more required params are missing"
        echo "ERROR: Required Args: contrail_version = $contrail_version"
        echo "ERROR: Required Args: tar_name = $tar_name"
        return 1
    fi
    tempdir=$(mktemp -d)
    for image in $(docker images |grep kolla | grep $contrail_version |awk '{print $1 ":" $3}'); do
        IFS=':' read image_name image_id <<< $image
        image_name=$(echo $image_name | cut -d "/" -f2)
        docker save $image_id | gzip > ${tempdir}/$image_name.tar.gz
        if [ $? != 0 ]; then
            echo "ERROR: Docker save for Image ($image_name), Image ID ($image_id) Failed..."
            return 1
        fi
     done
     (cd $tempdir && tar -czf $tar_name *.tar.gz) && \
     rm -rf $tempdir
}

