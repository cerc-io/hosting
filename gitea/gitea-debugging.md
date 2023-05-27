## Notes using a debugger with Gitea

### Changes to Gitea
Assuming the Gitea repository cloned at `/path/to/gitea` (adjust below for your actual location),
make the following changes to a cloned gitea repository then build a new container with:
```
$ docker build -t my-org/gitea:debug -f Dockerfile .
```

Gitea project changes:
Dockerfile adds delve debugger binary, adjust compiler flags to suit debugging, expose port 40000 for remote debugging.
```
diff --git a/Dockerfile b/Dockerfile
index 06481cdf5..a49fd0266 100644
--- a/Dockerfile
+++ b/Dockerfile
@@ -16,6 +16,10 @@ RUN apk --no-cache add build-base git nodejs npm
 COPY . ${GOPATH}/src/code.gitea.io/gitea
 WORKDIR ${GOPATH}/src/code.gitea.io/gitea

+RUN go install github.com/go-delve/delve/cmd/dlv@latest
+
+ENV EXTRA_GOFLAGS '-gcflags="all=-N -l"'
+
 #Checkout version if set
 RUN if [ -n "${GITEA_VERSION}" ]; then git checkout "${GITEA_VERSION}"; fi \
  && make clean-all build
@@ -26,7 +30,7 @@ RUN go build contrib/environment-to-ini/environment-to-ini.go
 FROM docker.io/library/alpine:3.18
 LABEL maintainer="maintainers@gitea.io"

-EXPOSE 22 3000
+EXPOSE 22 3000 40000

 RUN apk --no-cache add \
     bash \
@@ -65,6 +69,7 @@ COPY docker/root /
 COPY --from=build-env /go/src/code.gitea.io/gitea/gitea /app/gitea/gitea
 COPY --from=build-env /go/src/code.gitea.io/gitea/environment-to-ini /usr/local/bin/environment-to-ini
 COPY --from=build-env /go/src/code.gitea.io/gitea/contrib/autocompletion/bash_autocomplete /etc/profile.d/gitea_bash_autocomplete.sh
+COPY --from=build-env  /go/bin/dlv /usr/local/bin/
 RUN chmod 755 /usr/bin/entrypoint /app/gitea/gitea /usr/local/bin/gitea /usr/local/bin/environment-to-ini
 RUN chmod 755 /etc/s6/gitea/* /etc/s6/openssh/* /etc/s6/.s6-svscan/*
 RUN chmod 644 /etc/profile.d/gitea_bash_autocomplete.sh
 ```
Makefile removes linker flags that strip symbols:
 ```
diff --git a/Makefile b/Makefile
index 16841796b..35fdaf1de 100644
--- a/Makefile
+++ b/Makefile
@@ -789,7 +789,7 @@ check: test

 .PHONY: install $(TAGS_PREREQ)
 install: $(wildcard *.go)
-       CGO_CFLAGS="$(CGO_CFLAGS)" $(GO) install -v -tags '$(TAGS)' -ldflags '-s -w $(LDFLAGS)'
+       CGO_CFLAGS="$(CGO_CFLAGS)" $(GO) install -v -tags '$(TAGS)' -ldflags '$(LDFLAGS)'

 .PHONY: build
 build: frontend backend
@@ -817,7 +817,7 @@ security-check:
        go run $(GOVULNCHECK_PACKAGE) ./...

 $(EXECUTABLE): $(GO_SOURCES) $(TAGS_PREREQ)
-       CGO_CFLAGS="$(CGO_CFLAGS)" $(GO) build $(GOFLAGS) $(EXTRA_GOFLAGS) -tags '$(TAGS)' -ldflags '-s -w $(LDFLAGS)' -o $@
+       CGO_CFLAGS="$(CGO_CFLAGS)" $(GO) build $(GOFLAGS) $(EXTRA_GOFLAGS) -tags '$(TAGS)' -ldflags '$(LDFLAGS)' -o $@

 .PHONY: release
 release: frontend generate release-windows release-linux release-darwin release-freebsd release-copy release-compress vendor release-sources release-docs release-check
```
run script inserts delve as the executed binary, with appropriate commands for it to spawn the gitea binary on startup:
``` 
diff --git a/docker/root/etc/s6/gitea/run b/docker/root/etc/s6/gitea/run
index 7b858350f..26bd2eeb3 100755
--- a/docker/root/etc/s6/gitea/run
+++ b/docker/root/etc/s6/gitea/run
@@ -1,6 +1,25 @@
 #!/bin/bash
+if [ -n "$CERC_SCRIPT_DEBUG" ]; then
+    set -x
+fi
+
 [[ -f ./setup ]] && source ./setup

+GITEA="/app/gitea/gitea"
+WORK_DIR="/app/gitea"
+CUSTOM_PATH="/data/gitea"
+
+# Provide docker defaults
+export GITEA_WORK_DIR="${GITEA_WORK_DIR:-$WORK_DIR}"
+export GITEA_CUSTOM="${GITEA_CUSTOM:-$CUSTOM_PATH}"
+
+# exec -a "$0" "$GITEA" $CONF_ARG "$@"
+
+START_CMD="/usr/local/bin/gitea"
+if [ "true" == "$CERC_REMOTE_DEBUG" ] && [ -x "/usr/local/bin/dlv" ]; then
+    START_CMD="/usr/local/bin/dlv --listen=:40000 --headless=true --api-version=2 --accept-multiclient exec "$GITEA"  --continue --"
+fi
+
 pushd /app/gitea >/dev/null
-exec su-exec $USER /usr/local/bin/gitea web
+exec su-exec $USER $START_CMD $CONF_ARG web
 popd
```

### Changes to the compose config

1. Specify the newly build container image.
1. Enable remote debugging with `CERC_REMOTE_DEBUG=true`
1. Enable trace logging with `GITEA__log__LEVEL=Trace`
1. Mount the project source into the container (path must be the same absolute path as on the host)
1. Map the go debug port (40000 in this case) into the host.

```
diff --git a/gitea/docker-compose.yml b/gitea/docker-compose.yml
index 59fea80..35feed0 100644
--- a/gitea/docker-compose.yml
+++ b/gitea/docker-compose.yml
@@ -1,8 +1,9 @@

 services:
   server:
-    image: gitea/gitea:1.19.3
+    image: my-org/gitea:debug
     environment:
+      - CERC_REMOTE_DEBUG=true
       - USER_UID=1000
       - USER_GID=1000
       - GITEA__database__DB_TYPE=postgres
@@ -15,6 +16,7 @@ services:
       - GITEA__server__ROOT_URL=http://gitea.local:3000/
       - GITEA__actions__ENABLED=true
       - GITEA__security__INSTALL_LOCK=true
+      - GITEA__log__LEVEL=Trace
     restart: always
     extra_hosts:
       - "gitea.local:host-gateway"
@@ -22,10 +24,12 @@ services:
       - ./gitea:/data
       - /etc/timezone:/etc/timezone:ro
       - /etc/localtime:/etc/localtime:ro
+      - /path/to/gitea:/path/to/gitea:ro
     # TODO: remove fixed host port number
     ports:
       - "3000:3000"
       - "222:22"
+      - "40000:40000"
     depends_on:
       - db
```
### Debug with VSCode
Use a `launch.json` file like this:
```
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Container gitea",
            "type": "go",
            "request": "attach",
            "mode": "remote",
            "remotePath": "/path/to/gitea",
            "port": 40000,
            "host": "127.0.0.1",
            "substitutePath": [
                { "from": "/path/to/gitea", "to": "/go/src/code.gitea.io/gitea" }
            ]
        }
    ]
}
```
With the gitea container running it should now be possible to "Run with debugging" and set breakpoints in the source code. If the breakpoints are not solid dots, something is wrong.
