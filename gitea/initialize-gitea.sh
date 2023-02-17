#!/usr/bin/env bash
# Run this script once after bringing up gitea in docker compose
# TODO: add a check to detect that gitea has not fully initialized yet (no user relation error)
GITEA_USER=gitea_admin
GITEA_PASSWORD=admin1234
GITEA_USER_EMAIL=${GITEA_USER}@example.com
GITEA_NEW_ORGANIZATION=cerc-io
GITEA_URL_PREFIX=http://localhost:3000
CERC_GITEA_TOKEN_NAME=laconic-so-publication-token
if [[ -n "$CERC_SCRIPT_DEBUG" ]]; then
    set -x
fi
# Create admin user
# First check if it already exists
if [[ -z ${CERC_SO_COMPOSE_PROJECT} ]] ; then
    compose_command="docker compose"
else
    compose_command="docker compose -p ${CERC_SO_COMPOSE_PROJECT}"
fi
# HACK: sleep a bit because gitea may not be up yet (container reports it has started before service is available)
sleep 5
${compose_command} exec --user git server gitea admin user list --admin | grep -v -e "^ID" | awk '{ print $2 }' | grep ${GITEA_USER} > /dev/null
if [[ $? == 1 ]] ; then
    # Then create if it wasn't found
    ${compose_command} exec --user git server gitea admin user create --admin --username ${GITEA_USER} --password ${GITEA_PASSWORD} --email ${GITEA_USER_EMAIL}
fi
# Check if the token already exists
token_response=$( curl -s "${GITEA_URL_PREFIX}/api/v1/users/${GITEA_USER}/tokens" \
  -u ${GITEA_USER}:${GITEA_PASSWORD} \
  -H "Content-Type: application/json")
if [[ -n ${token_response} ]] ; then
    echo ${token_response}  | jq --exit-status -r 'to_entries[] | select(.value.name == "'${CERC_GITEA_TOKEN_NAME}'")'
    if [[ $? == 0 ]] ; then
        token_found=1
    fi
fi
if [[ ${token_found} != 1 ]] ; then
    # Create access token if not found
    # Note that we either create the token here, or we needed to be passed 
    # the token by the caller. This is because gitea won't release the token
    # plaintext post-creation.
    new_gitea_token=$( curl -s -X POST "${GITEA_URL_PREFIX}/api/v1/users/${GITEA_USER}/tokens" \
      -u ${GITEA_USER}:${GITEA_PASSWORD} \
      -H "Content-Type: application/json" \
      -d '{"name":"'${CERC_GITEA_TOKEN_NAME}'"}' \
      | jq -r .sha1 )
    echo "This is your gitea access token: ${new_gitea_token}. Keep it safe and secure, it can not be fetched again from gitea."
    CERC_GITEA_AUTH_TOKEN=${new_gitea_token}
else
    # If the token exists, then we must have been passed its value.
    # If we were not, then we fail hard here.
    if [[ -z ${CERC_GITEA_AUTH_TOKEN} ]] ; then
        echo "FATAL error: gitea auth token \"${CERC_GITEA_TOKEN_NAME}\" already exists but no CERC_GITEA_AUTH_TOKEN was provided"
        exit 1
    fi
fi
# Now that we're sure the token exists and is set in CERC_GITEA_AUTH_TOKEN,
# we can proceed with token-authenticated API requests below
# Create org
# First check if it already exists
curl -s "${GITEA_URL_PREFIX}/api/v1/admin/users/${GITEA_USER}/orgs" \
  -H "Authorization: token ${CERC_GITEA_AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  -H  "accept: application/json" \
  | jq --exit-status -r 'to_entries[] | select(.value.name == "'${GITEA_NEW_ORGANIZATION}'")' > /dev/null
if [[ $? != 0 ]] ; then
    # If it doesn't exist, create it
    # See: https://discourse.gitea.io/t/create-remove-organization-through-api/478
    curl -s -X POST "${GITEA_URL_PREFIX}/api/v1/admin/users/${GITEA_USER}/orgs" \
      -H "Authorization: token ${CERC_GITEA_AUTH_TOKEN}" \
      -H "Content-Type: application/json" \
      -H  "accept: application/json" \
      -d '{"username": "'${GITEA_NEW_ORGANIZATION}'"}' > /dev/null
    echo "Created the organization ${GITEA_NEW_ORGANIZATION}"
fi
echo "Success, gitea is properly initialized"
