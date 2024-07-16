#!/usr/bin/env bash

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

shellcheck \
    --shell=bash \
    --check-sourced \
    --source-path="${script_dir}" \
    "${script_dir}"/*.sh
