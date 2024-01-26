
# This file needs to be source'ed and the function join_cgroup called, by any script that goes on to run kind
# This is required due to issues with properly virtualizing the cgroup hierarchy that exist at present in docker
# See: https://github.com/earthly/earthly/blob/main/buildkitd/dockerd-wrapper.sh#L56
function configure_cgroup() {
    if [ -f "/sys/fs/cgroup/cgroup.controllers" ]; then
        echo >&2 "INFO: detected cgroup v2, configuring nested docker group"

        local cgroup_name="nested-dockerd" # NOTE: has to be the same as the function below (local var to prevent overriding in the caller)

        # move script to separate cgroup, to prevent the root cgroup from becoming threaded (which will prevent systemd images (e.g. kind) from running)
        mkdir /sys/fs/cgroup/${cgroup_name}
        echo $$ > /sys/fs/cgroup/${cgroup_name}/cgroup.procs

       # This script is run from inside entrypoint.sh
       # so we also need to move the parent pid into this new group, which is weird
       # TODO: we should unwrap this so $$ is all we need to move
        echo 1 > /sys/fs/cgroup/${cgroup_name}/cgroup.procs

        if [ "$(wc -l < /sys/fs/cgroup/cgroup.procs)" != "0" ]; then
            echo >&2 "WARNING: processes exist in the root cgroup; this may cause errors during cgroup initialization"
        fi

        root_cgroup_type="$(cat /sys/fs/cgroup/cgroup.type)"
        if [ "$root_cgroup_type" != "domain" ]; then
            echo >&2 "WARNING: expected cgroup type of \"domain\", but got \"$root_cgroup_type\" instead"
        fi
    fi
}

function join_cgroup() {
    local cgroup_name="nested-dockerd" # NOTE: has to be the same as the function above (local var to prevent overriding in the caller)
    echo $$ > /sys/fs/cgroup/${cgroup_name}/cgroup.procs
}
