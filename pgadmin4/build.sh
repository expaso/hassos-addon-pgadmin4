#!/bin/bash

#sudo apt-get install yq jq

archs=linux/$(yq -r '.arch | join(",linux/")' config.yaml)
version=$(yq -r '.version' config.yaml)

if [ -n "$1" ]; then
    archs=$1
fi

# Print the result
echo "Building version '$version' for platforms '$archs'"

# Build and Push
#    
docker buildx build \
    --push \
    --platform $archs \
    --cache-from type=registry,ref=husselhans/hassos-addon-pgadmin4:cache \
    --cache-to type=registry,ref=husselhans/hassos-addon-pgadmin4:cache,mode=max \
    --tag husselhans/hassos-addon-pgadmin4:$version \
    .
