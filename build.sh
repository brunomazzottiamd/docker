#!/usr/bin/env bash

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${script_dir}/config.sh"

docker build \
    --build-arg USER_REAL_NAME="${USER_REAL_NAME}" \
    --build-arg USER_EMAIL="${USER_EMAIL}" \
    --build-arg USER_ID="${USER_ID}" \
    --build-arg USER_NAME="${USER_NAME}" \
    --build-arg GROUP_ID="${GROUP_ID}" \
    --build-arg GROUP_NAME="${GROUP_NAME}" \
    --build-arg TRITON_DEV_DIR="${TRITON_DEV_DIR}" \
    --build-arg HOME_DIR="${HOME_DIR}" \
    --build-arg TRITON_REPO_DIR="${TRITON_REPO_DIR}" \
    --tag "${IMAGE_NAME}" \
    "${script_dir}"
