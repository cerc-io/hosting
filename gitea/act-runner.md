## Deploying Action Runners

IMPORTANT NOTE: you should be aware that anyone with the ability to modify code run under a CI job in the host Gitea (this includes anyone with commit rights; anyone with the ability to modify any dependency; anyone with the ability to modify dependent components such as base container images) CAN POTENTIALLY COMPROMISE (hack, take over, steal data from) the machine hosting a runner. Proceed with caution.

### Releases
Gitea publishes binary releases of [gitea/act_runner](https://gitea.com/gitea/act_runner/releases) for many platform and architectures, which can be used to deploy new action runners simply.

The following example uses `gitea/act_runner` 0.2.6 to deploy a runner on macOS Ventura 13.3 x64.

### Registration Token

> Note: Runners can be registered globally for an entire Gitea instance, for a specific organization, or for a single repo.  This example registers globally.

Before executing the runner, first obtain a registration token by visiting http://gitea.local:3000/admin/actions/runners, clicking the 'Create new Runner' button, and copying the displayed
registration token, for example, `FTyMBkcK9ErmD0wm8LfBzfXOUUlQA7dBJF6BB64Z`.

### Runner Registration and Startup

After you have obtained a registration token, download the `gitea/act_runner` release matching your platform and architecture and run it as follows:

```
# Download latest gitea/act_runner release for your platform.
$ wget https://gitea.com/gitea/act_runner/releases/download/latest/act_runner-0.2.6-darwin-amd64 && chmod a+x act_runner-0.2.6-darwin-amd64

# Register the runner with the Gitea instance using the token obtained above.
$ ./act_runner-0.2.6-darwin-amd64 register \
    --instance http://gitea.local:3000 \
    --labels 'darwin-latest-amd64:host,darwin-13-amd64:host' \
    --name 'darwin-amd64-001' \
    --token "FTyMBkcK9ErmD0wm8LfBzfXOUUlQA7dBJF6BB64Z" \
    --no-interactive

# Launch it in daemon mode, waiting for jobs.
$ ./act_runner-0.2.6-darwin-amd64 daemon
```

### Labels

The most important detail in this example is the label.  For the Ubuntu runner which is deployed automatically with this project, the label `ubuntu-latest:docker://cerc/act-runner-task-executor:local` is
used, which instructs `gitea/act_runner` that a task which `runs-on: ubuntu-latest` should be executed inside an instance of the `cerc/act-runner-task-executor:local` Docker container.  In this example, the label is `darwin-latest-amd64:host`.  This means that a task which `runs-on: darwin-latest-amd64` will be executed natively on the host machine.  Since there are additional security implications when executing tasks
on the host, only trusted repositories with strict access controls should be allowed to schedule CI jobs on the runner.

### Example Workflow

This very simple workflow will schedule jobs on both macOS (`darwin-latest-amd64`) and Linux (`ubuntu-latest`) runners.

```
name: macOS test

on:
  push:
    branches:
      - main

jobs:
  test-macos:
    name: "Run on macOS"
    runs-on: darwin-latest-amd64
    steps:
      - name: "uname"
        run: uname -a
  test-linux:
    name: "Run on Ubuntu"
    runs-on: ubuntu-latest
    steps:
      - name: "uname"
        run: uname -a
```
