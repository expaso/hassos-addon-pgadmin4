#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: pgAdmin4
# Configures pgAdmin4 before running
# ==============================================================================

# Populate config_distro.py. This has some default config, as well as anything
# provided by the user through the PGADMIN_CONFIG_* environment variables.
# Only update the file on first launch. The empty file is created during the
# container build so it can have the required ownership.
if [ `wc -m /pgadmin4/config_distro.py | awk '{ print $1 }'` = "0" ]; then
    cat << EOF > /pgadmin4/config_distro.py
HELP_PATH = '../../docs'
DEFAULT_BINARY_PATHS = {
        'pg': '/usr/local/pgsql-12'
}
EOF
fi

# Ensure configuration exists
if ! bashio::fs.directory_exists '/data/pgadmin4'; then
    mkdir -p /data/pgadmin4 \
        || bashio::exit.nok "Failed to create data directory"
fi

if [ ! -f /data/pgadmin4/pgadmin4.db ]; then
    # Initialize DB before starting Gunicorn
    # Importing pgadmin4 (from this script) is enough
    cd /pgadmin4
    python run_pgadmin.py || bashio::exit.nok "Failed to initialize Database"
fi

