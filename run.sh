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

# FIXME: Running container as user isn't working.
#        Add `--user "${USER_ID}:${GROUP_ID}" \` to `docker run` when it's fixed.
docker run \
    -it \
    --workdir "${TRITON_DEV_DIR}" \
    --network host \
    --device /dev/kfd \
    --device /dev/dri \
    --mount "type=bind,source=${HOME},target=${HOME_DIR}" \
    --name "${container_name}" \
    "${IMAGE_NAME}"
