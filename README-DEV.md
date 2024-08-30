# Local development

To build the lastest version using local docker, switch to the folder where the `dockerfile` resides, and run:

```
./build.sh
```

The dockerfile already contains the default build architecture and the default base image:

```
ARG BUILD_FROM=ghcr.io/hassio-addons/base/aarch64:16.2.1
ARG BUILD_ARCH=aarch64
```

This can also be done by passing the build-arguments by the commandline:

```
docker build --tag husselhans/hassos-addon-pgadmin4-armv7:dev . --build-arg BUILD_FROM=ghcr.io/hassio-addons/base/armv7:16.2.1
```

Hereafter, you can push the image to dockerhub using cmd of docker desktop for testing purposes.

## Build using Home Asssitant Builder

To build the latest version using the HomeAssistant Addon Builder container, for `aarch64 architecture` for example, run:

```
docker run --rm --privileged \
    -v ~/.docker:/root/.docker \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v ~/hassos-addon-pgadmin4/pgadmin4:/data homeassistant/amd64-builder \
    --addon \
    --target pgadmin4 \
    --aarch64 \
    --cache-tag cache \
    -t /data
```

This will use the base images from the `build.json` file, and the architecture specified. Use `--all` instead of `--aarch64` to build all architectures within the `config.json`for example.

## Push latest DEV image to repository

docker image push husselhans/hassos-addon-pgadmin4-aarch64:dev

## Run the addon with an interactive shell

From a system SSH (port 22222), run the docker container with data attached:

```
docker run -it --entrypoint "/bin/sh" -v /mnt/data/supervisor/addons/data/local_pgadmin4/:/data:rw  husselhans/hassos-addon-pgadmin4-aarch64:dev
```
