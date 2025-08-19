#!/usr/bin/env bash

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

echo "(load-file \"${script_dir}/emacs.el\")" >> ~/.emacs
