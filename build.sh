#!/usr/bin/env bash

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${script_dir}/config.sh"

docker build \
    --tag "${IMAGE_NAME}" \
    "${script_dir}"
