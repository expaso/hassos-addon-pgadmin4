#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: pgAdmin4
# Configures NGINX for use with pgAdmin4
# ==============================================================================
declare admin_port
declare certfile
declare dns_host
declare ingress_interface
declare ingress_port
declare ingress_entry
declare keyfile

# Check if there is a port mapping..
admin_port=$(bashio::addon.port 80)
if bashio::var.has_value "${admin_port}"; then
    bashio::config.require.ssl

    if bashio::config.true 'ssl'; then
        certfile=$(bashio::config 'certfile')
        keyfile=$(bashio::config 'keyfile')

        mv /etc/nginx/servers/direct-ssl.disabled /etc/nginx/servers/direct.conf
        sed -i "s#%%certfile%%#${certfile}#g" /etc/nginx/servers/direct.conf
        sed -i "s#%%keyfile%%#${keyfile}#g" /etc/nginx/servers/direct.conf

        admin_port=443
    else
        mv /etc/nginx/servers/direct.disabled /etc/nginx/servers/direct.conf

        admin_port=80
    fi

    sed -i "s/%%port%%/${admin_port}/g" /etc/nginx/servers/direct.conf
fi

# Patch ingress server to contain the correct portnumbers and paths
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
ingress_entry=$(bashio::addon.ingress_entry)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s#%%entry%%#${ingress_entry}#g" /etc/nginx/servers/ingress.conf

# Patch resolver to match DNS
dns_host=$(bashio::dns.host)
sed -i "s/%%dns_host%%/${dns_host}/g" /etc/nginx/includes/resolver.conf
