#!/usr/bin/env bash

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

"${script_dir}/add_bashrc.sh" && \
"${script_dir}/add_emacs_el.sh" && \
"${script_dir}/config_git.sh"
