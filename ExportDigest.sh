#!/usr/bin/env bash
# export remote digest to environment variable

docker manifest inspect pihole/pihole > /tmp/manifest.json

index=$(jq '.manifests | map(.platform.variant == "v7") | index(true)' /tmp/manifest.json)

if [[ $index == null ]]; then
	echo -e "$(date "+%Y-%m-%d %H:%M:%S") | Variant v7 for arm is missing in manifest file!\n" >> "$PWD/logs/updater.log"
  	exit 1;
fi

digest=$(jq -r --argjson a_index $index '.manifests[$a_index].digest' /tmp/manifest.json)
export REMOTE_DIGEST="$digest"
rm /tmp/manifest.json
