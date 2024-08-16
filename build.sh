#!/usr/bin/env bash

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${script_dir}/config.sh"

get_ssh_key() {
    ssh -G 'git@github.com' \
    | grep 'identityfile' \
    | cut --delimiter ' ' --fields=2 \
    | sed --expression "s|^~|${HOME}|" \
    | xargs realpath --canonicalize-existing --quiet \
    | head -1
}

docker build \
    --build-arg USER_REAL_NAME="${USER_REAL_NAME}" \
    --build-arg USER_EMAIL="${USER_EMAIL}" \
    --build-arg USER_ID="${USER_ID}" \
    --build-arg USER_NAME="${USER_NAME}" \
    --build-arg GROUP_ID="${GROUP_ID}" \
    --build-arg GROUP_NAME="${GROUP_NAME}" \
    --ssh default="$(get_ssh_key)" \
    --tag "${IMAGE_NAME}" \
    "${script_dir}"
