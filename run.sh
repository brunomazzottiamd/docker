#!/usr/bin/env bash


### Source common config.

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${script_dir}/config.sh"


### Utility functions.

trim_string() {
    : "${1#"${1%%[![:space:]]*}"}"
    : "${_%"${_##*[![:space:]]}"}"
    printf '%s\n' "$_"
}

container_status() {
    container_name="${1}"
    docker inspect --format '{{.State.Status}}' "${container_name}"
}

wait_for_running() {
    container_name="${1}"
    echo 'Waiting for container to be running...'
    while [ "$(container_status "${container_name}")" != running ]; do
        sleep 1
    done
}


### Set container name.

container_name_suffix=$(trim_string "${1}")
container_name="${IMAGE_NAME}"

if [ -n "${container_name_suffix}" ]; then
    container_name="${container_name}_${container_name_suffix}"
fi

echo "Target container is [${container_name}]".


### Check if container exists.

container_exists=$(
    docker ps --all --format '{{.Names}}' \
    | grep --word-regexp "${container_name}"
)

if [ -z "${container_exists}" ]; then
    echo 'Container does not exist. Creating it...'

    # FIXME: Running container as user isn't working.
    #        Add `--user "${USER_ID}:${GROUP_ID}"` to `docker run` when it's fixed.

    # FIXME: SSH bind mount target should be the container user home directory instead
    #        of the hardcoded `/root/.ssh`.

    docker run \
        -it \
        --detach \
        --name "${container_name}" \
        --network host \
        --ipc host \
        --device /dev/kfd \
        --device /dev/dri \
        --security-opt seccomp=unconfined \
        --cap-add SYS_PTRACE \
        --group-add video \
        --group-add render \
        --shm-size=16G \
        --ulimit memlock=-1 \
        --ulimit stack=67108864 \
        --mount "type=bind,source=${HOME},target=/triton_dev/hhome" \
        --mount "type=bind,source=${HOME}/.ssh,target=/root/.ssh,readonly" \
        --workdir /triton_dev \
        "${IMAGE_NAME}" \
        > /dev/null
else
    echo 'Container already exists.'
fi


### Check the status and take appropriate actions.

status=$(container_status "${container_name}")

case "${status}" in
    exited)
        echo 'Container is exited. Restarting it...'
        docker restart "${container_name}" > /dev/null
        wait_for_running "${container_name}"
        ;;
    paused)
        echo 'Container is paused. Unpausing it...'
        docker unpause "${container_name}" > /dev/null
        wait_for_running "${container_name}"
        ;;
    running)
        echo 'Container is running.'
        ;;
    *)
        echo "Unexpected container state: [${status}]"
        echo 'Exiting...'
        exit 1
        ;;
esac

docker exec -it "${container_name}" bash
