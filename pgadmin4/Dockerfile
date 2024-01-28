ARG BUILD_FROM=ghcr.io/hassio-addons/base/aarch64:15.0.5

#Source: https://github.com/postgres/pgadmin4/blob/master/Dockerfile
########################################################################
#
# pgAdmin 4 - PostgreSQL Tools
#
# Copyright (C) 2013 - 2022, The pgAdmin Development Team
# This software is released under the PostgreSQL Licence
#
#########################################################################

FROM --platform=$BUILDPLATFORM alpine:latest as app-builder

RUN --mount=type=cache,id=apk,sharing=locked,target=/var/cache/apk \
    apk add \
        autoconf \
        automake \
        bash \
        g++ \
        git \
        libc6-compat \
        libjpeg-turbo-dev \
        libpng-dev \
        libtool \
        make \
        nasm \
        nodejs \
        npm \
        yarn \
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

#### PATCH SOURCES ####
# Patch pgadmin-files to allow reverse proxying in desktop mode.
# This is needed to support ingress (which is on a deeper path below root)
# We want to run pfAdmin in desktop-mode (no users), because we would like to handle users and authentication ourselves.
# Problem is, in desktop mode, reverse-propxying is not respected.
# And so we patch the files to enale this behaviour again.
#sed -i '105s/config.SERVER_MODE/True/' /pgadmin4/pgadmin/__init__.py    #Line 105: Assume server-mode here to enable reverse-proxy
#sed -i '95s/config.SERVER_MODE/True/' /pgadmin4/pgAdmin4.py             #Line 94: Assume server-mode here to enable reverse-proxy
#######################
COPY patches/pgAdmin.patch /pgadmin4
WORKDIR /pgadmin4
RUN git apply -v pgAdmin.patch
#######################

WORKDIR /pgadmin4/web

# Build the JS vendor code in the app-builder, and then remove the vendor source.
RUN \
    --mount=type=cache,id=yarn,sharing=locked,target=/root/.yarn \
    export YARN_CACHE_FOLDER=/root/.yarn && \
    export CPPFLAGS="-DPNG_ARM_NEON_OPT=0" && \
        yarn set version berry && \
        yarn set version 3 && \
        yarn install && \
        yarn run bundle && \
        rm -rf node_modules \
            yarn.lock \
            package.json \
            .[^.]* \
            babel.cfg \
            webpack.* \
            jest.config.js \
            babel.* \
            ./pgadmin/static/js/generated/.cache

#########################################################################
# Next, create the base environment for Python
#########################################################################

FROM alpine:latest as env-builder

# Install dependencies
COPY official-pgadmin4/requirements.txt /

RUN --mount=type=cache,id=apk-$TARGETPLATFORM,sharing=locked,target=/var/cache/apk \
        apk add \
            make \
            python3 \
            py3-pip && \
        apk add --virtual build-deps \
            build-base \
            openssl-dev \
            libffi-dev \
            postgresql-dev \
            krb5-dev \
            rust \
            git \
            cargo \
            zlib-dev \
            libjpeg-turbo-dev \
            libpng-dev \
            python3-dev
RUN --mount=type=cache,id=pip-$TARGETPLATFORM,sharing=locked,target=/root/.cache \
        python3 -m venv --system-site-packages --without-pip /venv && \
        #/venv/bin/python3 -m pip install setuptools && \
        /venv/bin/python3 -m pip install -r requirements.txt && \
        apk del build-deps

#########################################################################
# Now, create a documentation build container for the Sphinx docs
#########################################################################

FROM env-builder as docs-builder

# Install Sphinx
RUN --mount=type=cache,id=pip-$TARGETPLATFORM,sharing=locked,target=/root/.cache \
        /venv/bin/python3 -m pip install sphinx && \
        /venv/bin/python3 -m pip install sphinxcontrib-youtube

# Copy the docs from the local tree. Explicitly remove any existing builds that
# may be present
COPY official-pgadmin4/docs /pgadmin4/docs
COPY official-pgadmin4/web /pgadmin4/web
RUN rm -rf /pgadmin4/docs/en_US/_build

# Build the docs
RUN LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 /venv/bin/sphinx-build /pgadmin4/docs/en_US /pgadmin4/docs/en_US/_build/html

# Cleanup unwanted files
RUN rm -rf /pgadmin4/docs/en_US/_build/html/.doctrees
RUN rm -rf /pgadmin4/docs/en_US/_build/html/_sources
RUN rm -rf /pgadmin4/docs/en_US/_build/html/_static/*.png

#########################################################################
# Create additional builders to get all of the PostgreSQL utilities
#########################################################################

FROM postgres:12-alpine AS pg12-builder
FROM postgres:13-alpine AS pg13-builder
FROM postgres:14-alpine AS pg14-builder
FROM postgres:15-alpine AS pg15-builder
FROM postgres:16-alpine AS pg16-builder

FROM alpine:latest as tool-builder

# Copy the PG binaries
COPY --from=pg12-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-12/
COPY --from=pg12-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-12/
COPY --from=pg12-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-12/
COPY --from=pg12-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-12/

COPY --from=pg13-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-13/
COPY --from=pg13-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-13/
COPY --from=pg13-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-13/
COPY --from=pg13-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-13/

COPY --from=pg14-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-14/
COPY --from=pg14-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-14/
COPY --from=pg14-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-14/
COPY --from=pg14-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-14/

COPY --from=pg15-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-15/
COPY --from=pg15-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-15/
COPY --from=pg15-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-15/
COPY --from=pg15-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-15/

COPY --from=pg16-builder /usr/local/bin/pg_dump /usr/local/pgsql/pgsql-16/
COPY --from=pg16-builder /usr/local/bin/pg_dumpall /usr/local/pgsql/pgsql-16/
COPY --from=pg16-builder /usr/local/bin/pg_restore /usr/local/pgsql/pgsql-16/
COPY --from=pg16-builder /usr/local/bin/psql /usr/local/pgsql/pgsql-16/

#########################################################################
# Assemble everything into the final container.
#########################################################################
FROM $BUILD_FROM 

# Copy in the Python packages
COPY --from=env-builder /venv /venv

# Copy in the tools
COPY --from=tool-builder /usr/local/pgsql /usr/local/
COPY --from=pg16-builder /usr/local/lib/libpq.so.5.16 /usr/lib/
COPY --from=pg16-builder /usr/lib/libzstd.so.1.5.5 /usr/lib/
COPY --from=pg16-builder /usr/lib/liblz4.so.1.9.4 /usr/lib/

RUN ln -s libpq.so.5.16 /usr/lib/libpq.so.5 && \
    ln -s libpq.so.5.16 /usr/lib/libpq.so && \
    ln -s libzstd.so.1.5.5 /usr/lib/libzstd.so.1 && \
    ln -s liblz4.so.1.9.4 /usr/lib/liblz4.so.1


WORKDIR /pgadmin4
ENV PYTHONPATH=/pgadmin4

# Copy in the code and docs
COPY --from=app-builder /pgadmin4/web /pgadmin4
COPY --from=docs-builder /pgadmin4/docs/en_US/_build/html/ /pgadmin4/docs
COPY official-pgadmin4/pkg/docker/run_pgadmin.py /pgadmin4
COPY official-pgadmin4/pkg/docker/gunicorn_config.py /pgadmin4
#COPY official-pgadmin4/pkg/docker/entrypoint.sh /entrypoint.sh

# License files
COPY official-pgadmin4/LICENSE /pgadmin4/LICENSE
COPY official-pgadmin4/DEPENDENCIES /pgadmin4/DEPENDENCIES

# Install runtime dependencies and configure everything in one RUN step
RUN --mount=type=cache,id=apk-$TARGETPLATFORM,target=/var/cache/apk \
    apk --force-broken-world add \
        python3 \
        py3-pip \
        postfix \
        krb5-libs \
        libjpeg-turbo \
        shadow \
        sudo \
        tzdata \
        libedit \
        libldap \
        libcap
RUN --mount=type=cache,id=pip-$TARGETPLATFORM,sharing=locked,target=/root/.cache \
        /venv/bin/python3 -m pip install --no-cache-dir gunicorn==20.1.0 && \
        find / -type d -name '__pycache__' -exec rm -rf {} + && \
        useradd -r -u 5050 -g root -s /sbin/nologin pgadmin && \
        mkdir -p /var/lib/pgadmin && \
        chown pgadmin:root /var/lib/pgadmin && \
        chmod g=u /var/lib/pgadmin && \
        touch /pgadmin4/config_distro.py && \
        chown pgadmin:root /pgadmin4/config_distro.py && \
        chmod g=u /pgadmin4/config_distro.py && \
        chmod g=u /etc/passwd && \
        setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/python3.11 && \
        echo "pgadmin ALL = NOPASSWD: /usr/sbin/postfix start" > /etc/sudoers.d/postfix && \
        echo "pgadminr ALL = NOPASSWD: /usr/sbin/postfix start" >> /etc/sudoers.d/postfix

# --------------------------------------
# Finish image (Different from official pgAdmin)
# --------------------------------------

# Install NGINX for Ingress support
RUN apk add --no-cache \
        git \
        lua-resty-http \
        nginx-mod-http-lua \
        nginx

# Precompile and optimize python code to save time and space on startup
RUN /venv/bin/python3 -O -m compileall -x node_modules /pgadmin4

# Make sure that S6 is not so hard on our service startup/shutdown
ENV \
    S6_SERVICES_GRACETIME=240000
ENV \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=120000

ENV \
    PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION="False" \
    PGADMIN_CONFIG_WTF_CSRF_CHECK_DEFAULT="False" \
    PGADMIN_CONFIG_WTF_CSRF_ENABLED="False"

# Copy data
COPY  rootfs /
RUN chmod +x /etc/cont-init.d/* \
    && chmod +x /etc/services.d/nginx/* \
    && chmod +x /etc/services.d/pgadmin4/*

#USER pgadmin

WORKDIR /
