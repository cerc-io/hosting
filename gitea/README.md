## Deployment notes
### Gitea
1. `cd ./gitea`
1. Run the script `./run-this-first.sh`
1. Bring up the gitea cluster `docker compose up -d`
1. Run the script `./initialize-gitea.sh`
1. Note the access token printed, it will be needed to publish packages.
