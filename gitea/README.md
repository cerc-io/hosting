## Deployment Notes
### Gitea

#### Build gitea/act_runner Docker Container
1. To build the `act_runner` container from Gitea, in another directory run:
```
git clone https://gitea.com/gitea/act_runner
cd act_runner
docker build -t cerc/act-runner:local .
```

#### Deploy Gitea Stack
1. `cd ./gitea`
1. Build the task executor container: `docker build -t cerc/act-runner-task-executor:local -f Dockerfile.task-executor .`
1. Run the script `./run-this-first.sh`
1. Bring up the gitea cluster `docker compose up -d`
1. Run the script `./initialize-gitea.sh`
1. Note the access token printed, it will be needed to publish packages.

#### Debugging
Gitea server logs can be seen via docker logs <container-id>.
To enable more verbose log output add an environment variable definition like:
```
GITEA__log__LEVEL=TRACE
```
to the `server` definition in `docker-compose.yml` and re-start.
Details on how to setup remote debugging of the gitea server inside its container can be found [here](gitea-debugging.md).

#### Action Runners

A Dockerized action runner is deployed by default for the labels `ubuntu-latest` and `ubuntu-22.04`.  Details on deploying
additional runners can be found [here](act-runner.md).
