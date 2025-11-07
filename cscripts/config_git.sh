#!/usr/bin/env bash

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

source "${script_dir}/../config.sh"

git config --global user.name "${USER_REAL_NAME}" && \
git config --global user.email "${USER_EMAIL}" && \
git config --global core.editor "${script_dir}/editor.sh"
