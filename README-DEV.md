# Local development

Initialize the pgAdmin source submodule before building:

```
git submodule update --init --recursive
```

To build the lastest version using local docker, switch to the folder where the `dockerfile` resides, and run:

```
./build.sh
```

The Dockerfile contains a default base image:

```
ARG BUILD_FROM=ghcr.io/hassio-addons/base/aarch64:21.0.11
```

Set the platform, base image and architecture together when building manually:

```
docker build --platform linux/amd64 --tag ghcr.io/expaso/pgadmin4/amd64:dev . \
    --build-arg BUILD_FROM=ghcr.io/hassio-addons/base/amd64:21.0.11 \
    --build-arg BUILD_ARCH=amd64 --build-arg BUILD_VERSION=dev
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

docker image push ghcr.io/expaso/pgadmin4/aarch64:dev

## Run the addon with an interactive shell

From a system SSH (port 22222), run the docker container with data attached:

```
docker run -it --entrypoint "/bin/sh" -v /mnt/data/supervisor/addons/data/local_pgadmin4/:/data:rw  ghcr.io/expaso/pgadmin4/aarch64:dev
```
