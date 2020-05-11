ARG BUILD_FROM
ARG BUILD_ARCH

#Source: https://github.com/postgres/pgadmin4/blob/master/Dockerfile
########################################################################
#
# pgAdmin 4 - PostgreSQL Tools
#
# Copyright (C) 2013 - 2018, The pgAdmin Development Team
# This software is released under the PostgreSQL Licence
#
#########################################################################

#########################################################################
# Create a Node container which will be used to build the JS components
# and clean up the web/ source code
#########################################################################

FROM node:10-alpine AS app-builder

RUN apk add --no-cache \
    autoconf \
    automake \
    bash \
    g++ \
    libc6-compat \
    libjpeg-turbo-dev \
    libpng-dev \
    make \
    nasm \
    git \
    zlib-dev

# Create the /pgadmin4 directory and copy the source into it. Explicitly
# remove the node_modules directory as we'll recreate a clean version, as well
# as various other files we don't want
COPY official-pgadmin4/web /pgadmin4/web
RUN rm -rf /pgadmin4/web/*.log \
           /pgadmin4/web/config_*.py \
           /pgadmin4/web/node_modules \
           /pgadmin4/web/regression \
           `find /pgadmin4/web -type d -name tests` \
           `find /pgadmin4/web -type f -name .DS_Store`

WORKDIR /pgadmin4/web

# Build the JS vendor code in the app-builder, and then remove the vendor source.
RUN npm install && \
	npm audit fix && \
	rm -f yarn.lock && \
	yarn import
# Commented the below line to avoid vulnerability in decompress package and
# audit only dependencies folder. Refer https://www.npmjs.com/advisories/1217.
# Pull request is already been send https://github.com/kevva/decompress/pull/73,
# once fixed we will uncomment it.
#	yarn audit && \
#RUN	yarn audit --groups dependencies && \
RUN	rm -f package-lock.json && \
    yarn run bundle && \
    rm -rf node_modules \
           yarn.lock \
           package.json \
           .[^.]* \
           babel.cfg \
           webpack.* \
           karma.conf.js \
           ./pgadmin/static/js/generated/.cache

#########################################################################
# Now, create a documentation build container for the Sphinx docs
#########################################################################

FROM python:3.7-alpine3.10 as docs-builder

# Install only dependencies absolutely required for documentation building
RUN apk add --no-cache \
        make \
        build-base \
        openssl-dev \
        libffi-dev && \
        pip install --no-cache-dir \
        sphinx \
        flask_security_too \
        flask_paranoid \
        python-dateutil \
        flask_sqlalchemy \
        flask_gravatar \
        flask_migrate \
        simplejson \
        cryptography

# Copy the docs from the local tree. Explicitly remove any existing builds that
# may be present
COPY official-pgadmin4/docs /pgadmin4/docs
COPY official-pgadmin4/web /pgadmin4/web
RUN rm -rf /pgadmin4/docs/en_US/_build

# Build the docs
RUN LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 make -C /pgadmin4/docs/en_US -f Makefile.sphinx html

#########################################################################
# Create additional builders to get all of the PostgreSQL utilities
#########################################################################

FROM --platform=${BUILD_ARCH} postgres:9.4-alpine as pg94-builder
FROM --platform=${BUILD_ARCH} postgres:9.5-alpine as pg95-builder
FROM --platform=${BUILD_ARCH} postgres:9.6-alpine as pg96-builder
FROM --platform=${BUILD_ARCH} postgres:10-alpine as pg10-builder
FROM --platform=${BUILD_ARCH} postgres:11-alpine as pg11-builder
FROM --platform=${BUILD_ARCH} postgres:12-alpine as pg12-builder

FROM --platform=${BUILD_ARCH} alpine:3.11 as tool-builder

# Copy the PG binaries
COPY --from=pg94-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-9.4/
COPY --from=pg94-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-9.4/
COPY --from=pg94-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-9.4/
COPY --from=pg94-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-9.4/

COPY --from=pg95-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-9.5/
COPY --from=pg95-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-9.5/
COPY --from=pg95-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-9.5/
COPY --from=pg95-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-9.5/

COPY --from=pg96-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-9.6/
COPY --from=pg96-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-9.6/
COPY --from=pg96-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-9.6/
COPY --from=pg96-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-9.6/

COPY --from=pg10-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-10/
COPY --from=pg10-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-10/
COPY --from=pg10-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-10/
COPY --from=pg10-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-10/

COPY --from=pg11-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-11/
COPY --from=pg11-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-11/
COPY --from=pg11-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-11/
COPY --from=pg11-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-11/

COPY --from=pg12-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-12/
COPY --from=pg12-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-12/
COPY --from=pg12-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-12/
COPY --from=pg12-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-12/

#########################################################################
# Assemble everything into the final container.
#########################################################################

FROM $BUILD_FROM
#python:3.7-alpine3.10

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=tool-builder /usr/local/pgsql /usr/local/

WORKDIR /pgadmin4
ENV PYTHONPATH=/pgadmin4

# Copy in the code and docs
COPY --from=app-builder /pgadmin4/web /pgadmin4
COPY --from=docs-builder /pgadmin4/docs/en_US/_build/html/ /pgadmin4/docs
COPY official-pgadmin4/requirements.txt /pgadmin4/requirements.txt

#--------------------------------------------------------------------------
# Install Python 3
# This hack is widely applied to avoid python printing issues in docker containers.
# See: https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/pull/13
ENV PYTHONUNBUFFERED=1
RUN echo "**** install Python ****" && \
    apk add --no-cache python3 python3-dev && \
    if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi && \
    \
    echo "**** install pip ****" && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --no-cache --upgrade pip setuptools wheel && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi
#--------------------------------------------------------------------------

# Install build-dependencies, build & install C extensions and purge deps in
# one RUN step
RUN apk add --no-cache --virtual \
        build-deps \
        build-base \
        postgresql-dev \
        libffi-dev \
        linux-headers && \
    apk add \
        postfix \
        postgresql-client \
        postgresql-libs \
        shadow \
        sudo \
        libcap && \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir gunicorn==19.9.0 && \
    apk del --no-cache build-deps && \
    echo "pgadmin ALL = NOPASSWD: /usr/sbin/postfix start" > /etc/sudoers.d/postfix

# We need the v12 libpq, which is only in the 'edge' build of Alpine at present
COPY --from=pg12-builder /usr/local/lib/libpq.so.5.12 /usr/lib/
RUN ln -sf /usr/lib/libpq.so.5.12 /usr/lib/libpq.so.5

# Copy the runner script
COPY official-pgadmin4/pkg/docker/run_pgadmin.py /pgadmin4

# Precompile and optimize python code to save time and space on startup
RUN python -O -m compileall -x node_modules /pgadmin4

# Create pgadmin user
RUN groupadd -g 5050 pgadmin && \
    useradd -r -u 5050 -g pgadmin pgadmin && \
    mkdir -p /var/lib/pgadmin && \
    chown pgadmin:pgadmin /var/lib/pgadmin && \
    mkdir -p /var/log/pgadmin && \
    chown pgadmin:pgadmin /var/log/pgadmin && \
    touch /pgadmin4/config_distro.py && \
    chown pgadmin:pgadmin /pgadmin4/config_distro.py && \
    setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/python3.8

# Install NGINX for Ingress support
RUN \
    apk add --no-cache \
        git \
        lua-resty-http \
        nginx-mod-http-lua \
        nginx

# --------------------------------------
# Finish image
# --------------------------------------

# Make sure that S6 is not so hard on our service startup/shutdown
ENV \
    S6_SERVICES_GRACETIME=18000

# Copy data
COPY rootfs /

WORKDIR /
