#!/bin/env bash
# Run this script once after bringing up gitea in docker compose
# TODO: add checks to make the script idempotent
GITEA_USER=gitea_admin
GITEA_PASSWORD=admin1234
GITEA_USER_EMAIL=${GITEA_USER}@example.com
GITEA_NEW_ORGANIZATION=cerc-io
GITEA_URL_PREFIX=http://localhost:3000
# Create admin user
docker compose exec --user git server gitea admin user create --admin --username ${GITEA_USER} --password ${GITEA_PASSWORD} --email ${GITEA_USER_EMAIL}
# Create access token
curl -X POST "http://${GITEA_URL_PREFIX}/api/v1/users/${GITEA_USER}/tokens" \
  -u ${GITEA_USER}:${GITEA_PASSWORD} \
  -H "Content-Type: application/json" \
  -d '{"name":"laconic-so-publication-token"}'
# Create org
# See: https://discourse.gitea.io/t/create-remove-organization-through-api/478
curl -X POST "${GITEA_URL_PREFIX}/api/v1/admin/users/${GITEA_USER}/orgs" \
  -H "Authorization: token ${GITEA_TOKEN}" \
  -H "Content-Type: application/json" \
  -H  "accept: application/json" \
  -d '{"username": "'${GITEA_NEW_ORGANIZATION}'"}'
