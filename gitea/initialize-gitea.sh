#!/bin/env bash
# Run this script once after bringing up gitea in docker compose
docker compose exec --user git server gitea admin user create --admin --username gitea_admin --password admin1234 --email gitea_admin@example.com
