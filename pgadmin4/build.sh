#!/bin/bash

set -e

#sudo apt-get install yq jq

# Get the archs from the config.yaml file using yq
archs=linux/$(yq -r '.arch | join(",linux/")' config.yaml)
# Get the version from the config.yaml file using yq
version=$(yq -r '.version' config.yaml)

# Parse the arguments, overwrite the defaults
while [[ $# -gt 0 ]]; do
    key=$1
    case $key in
        -a|--architecture)
            archs=$2
            shift
            ;;
        -v|--version)
            version=$2
            shift
            ;;
        *)
            echo "$0 : Argument '$1' unknown";
            exit 1;
            ;;
    esac
    shift
done

# Print the result
echo "Building version '$version' for platforms '$archs'"

# error: failed to solve: ghcr.io/hassio-addons/base/armv7:15.0.5: error getting credentials - err: exec: "docker-credential-desktop.exe": executable file not found in $PATH, out: `
#Solution:
#In ~/.docker/config.json change credsStore to credStore

# docker run --rm --privileged \
#     -v ~/.docker:/root/.docker \
#     -v /var/run/docker.sock:/var/run/docker.sock \
#     -v ~/hassos-addon-pgadmin4/pgadmin4:/data homeassistant/amd64-builder \
#     --addon \
#     --target pgadmin4 \
#     --all \
#     --cache-tag cache \
#     -t /data

# Build and Push


for arch in $(yq -r '.arch[]' config.yaml); do

    ##translate the arch to the docker buildx arch
    case $arch in
        "aarch64")
            platform="linux/aarch64"
            ;;
        "amd64")
            platform="linux/amd64"
            ;;
        "armhf")
            platform="linux/armhf"
            ;;
        "armv7")
            platform="linux/arm/v7"
            ;;
        "i386")
            platform="linux/i386"
            ;;
        *)
            echo "Unknown architecture: $arch"
            exit 1
            ;;
    esac


    echo "Building for: $arch"
    # build the image
    docker buildx build \
        --push \
        --platform $platform \
        --cache-from type=registry,ref=husselhans/hassos-addon-pgadmin4:cache \
        --cache-to type=registry,ref=husselhans/hassos-addon-pgadmin4:cache,mode=max \
        --tag husselhans/hassos-addon-pgadmin4-$arch:$version \
        --build-arg BUILD_FROM=ghcr.io/hassio-addons/base/$arch:15.0.5 \
        --progress plain \
        .
done
