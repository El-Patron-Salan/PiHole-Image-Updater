#!/usr/bin/env bash

set -e

# First of all you should head to DockerHub: https://hub.docker.com/r/pihole/pihole/tags , expand latest tag and copy digest of linux/arm/v7 
# Then pull it: docker pull pihole/pihole@digest
## !!! Don't pull image simply by tag, because digest won't match with the one from DockerHub (https://github.com/docker/hub-feedback/issues/1925)


# Get the digest of a image tag from docker hub and compare it with local digest
# If they're the same skip it
# Otherwise remove container and image, pull image by digest and restart docker-compose
# Afterwards log changes to local file

# Return the digest of image for armv7 architecture
get_remote_digest() {

    docker manifest inspect pihole/pihole > manifest.json
    # Get index of array where armv7 is contained
    index=$(jq '.manifests | map(.platform.variant == "v7") | index(true)' manifest.json)
    
    if [[ $index == null ]]; then
        echo -e "$date_now | Variant v7 for arm is missing in manifest file!\n" >> /path/to/logger.log
        exit 1;
    fi

    get_digest=$(jq -r --argjson a_index $index '.manifests[$a_index].digest' manifest.json)
    echo "$get_digest"
}

# Return local digest of image
get_local_digest() {
    l_digest=$(docker inspect pihole/pihole | jq -r '.[].RepoDigests[0]' | sed 's/^.*sha256/sha256/')

    if [[ $l_digest != *"sha256"* ]]; then
        echo -e "$date_now | There seems to be problem with local digest!\n" >> /path/to/logger.log
        exit 1;
    fi

    echo "$l_digest"
}


remote_digest=$(get_remote_digest)
local_digest=$(get_local_digest)

container_id=$(docker ps -aqf "name=pihole")
image_id=$(docker images -q pihole/pihole)


# Current date
printf -v date_now '%(%Y-%m-%d %H:%M:%S)T' -1

if [[ $remote_digest != $local_digest ]]; then
    docker container stop $container_id && docker container rm $container_id && docker image rm $image_id && docker pull pihole/pihole@$remote_digest && docker-compose down && docker-compose up -d ;
    
    # After running series of commands check if container is behaving as expected
    check_if_exist_run=$(docker ps -q -f name={pihole})
    if [[ -n "$check_if_exist_run" ]]; then
        echo -e "$date_now | Container does not exist/run" >> /path/to/logger.log
        exit 1;
    fi
    echo -e "$date_now | Image successfully pulled from repository\n" >> /path/to/logger.log

elif [[ $remote_digest == $local_digest ]]; then
    echo -e "$date_now | Image is up to date\n" >> /path/to/logger.log

else
    echo -e "$date_now | Problem occured\n" >> /path/to/logger.log
fi