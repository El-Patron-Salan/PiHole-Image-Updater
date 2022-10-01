#!/usr/bin/env bash

# First of all you should head to DockerHub: https://hub.docker.com/r/pihole/pihole/tags , expand latest tag and copy digest of linux/arm/v7 
# Then pull it: docker pull pihole/pihole@digest
## !!! Don't pull image simply by tag, because digest won't match with the one from DockerHub (https://github.com/docker/hub-feedback/issues/1925)


# Get the digest of a image tag from docker hub and compare it with local digest
# If they're the same skip it
# Otherwise remove container and image, pull image by digest and restart docker-compose
# Afterwards log changes to local file

container_id=$(docker ps -aqf "name=pihole")
image_id=$(docker images -q pihole/pihole)

DATE_NOW=$(date "+%Y-%m-%d %H:%M:%S")
LOGS_PATH=$PWD/logs/updater.log

# Return local digest of image
local_digest() {
    l_digest=$(docker inspect $image_id | jq -r '.[].RepoDigests[0]' | sed 's/^.*sha256/sha256/')

    if [[ $l_digest != *"sha256"* ]]; then
        echo -e "$DATE_NOW | There seems to be problem with local digest!\n" >> $LOGS_PATH
        exit 1;
    fi

    echo "$l_digest"
}

if [[ -z "{$REMOTE_DIGEST}" ]]; then
    echo -e "$DATE_NOW | Environment variable is empty" >> $LOGS_PATH
    exit 1;
fi

if [[ $(docker images | grep -q "pihole"; echo $?) -eq 1 ]]; then
    echo -e "$DATE_NOW | PiHole image missing - pulling new" >> $LOGS_PATH
    docker-compose up -d --build && echo -e "$DATE_NOW | Successfully pulled\n" >> $LOGS_PATH

elif [[ $REMOTE_DIGEST != `local_digest` ]]; then
    docker container stop $container_id && docker container rm $container_id && docker image rm $image_id && docker-compose up -d --build;

    # After running commands check if container is behaving as expected
    check_existence=$(docker ps -q -f name="pihole")
    if [[ -n "$check_existence" ]]; then
        echo -e "$DATE_NOW | Container wasn't created\n" >> $LOGS_PATH
	    exit 1;
    fi
    echo -e "$DATE_NOW | Image successfully pulled from repository\n" >> $LOGS_PATH

elif [[ $REMOTE_DIGEST == `local_digest` ]]; then
    echo -e "$DATE_NOW | Image is up to date\n" >> $LOGS_PATH

else
    echo -e "$DATE_NOW | Problem occured\n" >> $LOGS_PATH
fi
