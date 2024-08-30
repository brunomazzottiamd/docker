#!/usr/bin/env bash

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${script_dir}/config.sh"

trim_string() {
    : "${1#"${1%%[![:space:]]*}"}"
    : "${_%"${_##*[![:space:]]}"}"
    printf '%s\n' "$_"
}

container_name_suffix=$(trim_string "${1}")
container_name="${IMAGE_NAME}"

if [ -n "${container_name_suffix}" ]; then
    container_name="${container_name}_${container_name_suffix}"
fi

# TODO: Check if container is running before executing `docker run`.
# docker start \
#     --attach \
#     --interactive \
#     "${container_name}" &> /dev/null

docker run \
    -it \
    --name "${container_name}" \
    --device /dev/kfd \
    --device /dev/dri \
    --network host \
    --mount "type=bind,source=${HOME},target=/triton_dev/hhome" \
    --mount "type=bind,source=${HOME}/.ssh,target=/triton_dev/chome/.ssh,readonly" \
    --user "${USER_ID}:${GROUP_ID}" \
    --workdir /triton_dev \
    "${IMAGE_NAME}"
