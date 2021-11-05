#!/usr/bin/env bash


# Get the digest of a image tag from docker hub and compare it with local digest
# If they're the same skip it
# Else pull new image, remove the old one and restart docker-compose
# Afterwards log changes to local file


# Get digest of a specific remote image tag
get_remote_digest(){

    # Grab token for later authentication
    get_token=$(curl --silent "https://auth.docker.io/token?scope=repository:pihole/pihole:pull&service=registry.docker.io" | jq -r '.token')

    digest=$(curl --silent --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
	--header "Authorization: Bearer $get_token" \
	"https://registry.hub.docker.com/v2/pihole/pihole/manifests/latest" | jq -r '.config.digest')
    
    echo "$digest"
}

# Get digest of local image (from manifest) that is used for x86_64
get_local_digest(){
    
    local_digest=$(docker manifest inspect --verbose pihole/pihole | jq -r '.[].SchemaV2Manifest.config.digest' | head -n 1)

    echo "$local_digest"
}

# I've to find shorter solution for getting image ID
# The image ID is an array of numbers from sha256 hash in range -> [7;18]
# The function below will have to extract these numbers from a hash
# !Important note:
# It differs from the previous function, because here we're taking a digest for arm architecture
# since this pihole is running on rpi
get_old_image_id(){
    
    local_digest_arm=$(docker manifest inspect --verbose pihole/pihole | jq -r '.[].SchemaV2Manifest.config.digest' | sed "4q;d")
    extract_id=${local_digest_arm:7:12}

    echo "$extract_id"
}

var_remote_digest=$(get_remote_digest)
var_local_digest=$(get_local_digest)
var_image_id=$(get_old_image_id)

date_now=$(date + '%Y-%m-%d %H:%M:%S')

if [ $var_remote_digest != $var_local_digest ]; then
    docker image rm $var_image_id && docker pull pihole/pihole && docker-compose down && docker-compose up -d ;
    echo -e "$date_now | Image pulled from repository\n" >> logger.log
else
    echo -e "$date_now | Image is up to date\n" >> logger.log
fi
