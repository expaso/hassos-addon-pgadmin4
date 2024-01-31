#!/bin/bash

#sudo apt-get install yq jq

archs=linux/$(yq -r '.arch | join(",linux/")' config.yaml)
version=$(yq -r '.version' config.yaml)

if [ -n "$1" ]; then
    archs=$1
fi

# Print the result
echo "Building version '$version' for platforms '$archs'"

# error: failed to solve: ghcr.io/hassio-addons/base/armv7:15.0.5: error getting credentials - err: exec: "docker-credential-desktop.exe": executable file not found in $PATH, out: `
#Solution:
#In ~/.docker/config.json change credsStore to credStore


#docker run --rm --privileged \
#    -v ~/.docker:/root/.docker \
#    -v /var/run/docker.sock:/var/run/docker.sock \
#    -v ~/hassos-addon-pgadmin4/pgadmin4:/data homeassistant/amd64-builder \
#    --addon \
#    --target pgadmin4 \
#    --all \
#    --cache-tag cache \
#    -t /data

# Build and Push

# For each arch in config.yaml, run the buildx build command

# Get the archs from the config.yaml file using yq
for arch in $(yq -r '.arch[]' config.yaml); do
    echo "Building for: $arch"
    # build the image
    docker buildx build \
        --push \
        --platform linux/$arch \
        --cache-from type=registry,ref=husselhans/hassos-addon-pgadmin4:cache \
        --cache-to type=registry,ref=husselhans/hassos-addon-pgadmin4-$arch:cache,mode=max \
        --tag husselhans/hassos-addon-pgadmin4-$arch:$version \
        --build-arg BUILD_FROM=ghcr.io/hassio-addons/base/$arch:15.0.5 \
        --progress plain \
        .
done
