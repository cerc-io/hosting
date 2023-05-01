#!/usr/bin/env bash
if [[ -n "$CERC_SCRIPT_DEBUG" ]]; then
    set -x
fi
set -e
mkdir -p ./nginx
mkdir -p ./certbot/certificates
mkdir -p ./certbot/challenge
# TODO: get from the caller
LACONIC_TLS_DOMAIN=example.com
LACONIC_ORIGIN_SERVICE_URL=http://example-webservice:8000/
# Expand the config template into the nginx config file
cat ./nginx-config-template | sed 's/${LACONIC_TLS_DOMAIN}/'${LACONIC_TLS_DOMAIN}'/' | \
	sed 's/${LACONIC_ORIGIN_SERVICE_URL}/'${LACONIC_ORIGIN_SERVICE_URL}'/' > ./nginx/nginx.conf
# Create a self-signed cert so nginx will start without us changing its config between pre and post certbot invocation.
# Check if we have a cert already
tls_certificate_directory=./certbot/certificates/live/${LACONIC_TLS_DOMAIN}
tls_certificate_directory_in_container=/etc/letsencrypt/live/${LACONIC_TLS_DOMAIN}
tls_certificate_file_name=${tls_certificate_directory}/fullchain.pem
# TODO: this won't work if there's a delay of more than one day between generating the 
# self signed cert and starting the certbot enrollment process
if [[ ! -f ${tls_certificate_file_name} ]] ; then
    echo "Generating self-signed certificate for ${LACONIC_TLS_DOMAIN}:"
    mkdir -p ${tls_certificate_directory}
    docker compose run --rm --entrypoint "\
        openssl req -x509 -nodes -newkey rsa:4096 -days 1 -keyout '${tls_certificate_directory_in_container}/privkey.pem' \
        -out '${tls_certificate_directory_in_container}/fullchain.pem' -subj '/CN=${LACONIC_TLS_DOMAIN}'" certbot
echo
fi
