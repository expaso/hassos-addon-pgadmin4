ARG BUILD_FROM=ghcr.io/hassio-addons/base/aarch64:16.2.1

FROM ${BUILD_FROM}

ARG TARGETPLATFORM
ARG CACHEBUST
ARG TARGETARCH

RUN --mount=type=cache,id=test-${TARGETARCH},sharing=locked,target=/root/.cache \
    echo "$CACHEBUST" > /root/.cache/cachebust-${TARGETARCH} && \
    ls -l /root/.cache

RUN --mount=type=cache,id=test-${TARGETARCH},sharing=locked,target=/root/.cache \
    echo "$CACHEBUST" > /root/.cache/cachebust-${TARGETARCH} && \
    ls -l /root/.cache && \
    echo "$CACHEBUST" > /root/.cache/x-${TARGETARCH}.txt && \
    ls -l /root/.cache

FROM ${BUILD_FROM}

ARG TARGETPLATFORM
ARG CACHEBUST
ARG TARGETARCH

RUN --mount=type=cache,id=test-${TARGETARCH},sharing=locked,target=/root/.cache \
    echo "$CACHEBUST" > /root/.cache/cachebust-${TARGETARCH} && \
    ls -l /root/.cache

RUN --mount=type=cache,id=test-${TARGETARCH},sharing=locked,target=/root/.cache \
    echo "$CACHEBUST" > /root/.cache/cachebust-${TARGETARCH} && \
    ls -l /root/.cache && \
    echo "$CACHEBUST" > /root/.cache/x-${TARGETARCH}.txt && \
    ls -l /root/.cache


#docker buildx build --push --platform linux/aarch64,linux/amd64 --cache-from husselhans/test:cache --cache-to husselhans/test:cache,mode=max --progress=plain . --tag husselhans/test:latest --build-arg CACHEBUST=$(date +%s)