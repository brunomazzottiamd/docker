#!/usr/bin/env bash

triton_cache_dir="${HOME}/.triton/cache"

if [ -d "${triton_cache_dir}" ]; then
    count=$(find "${triton_cache_dir}" -type f -name '*.amdgcn' | wc --lines)
    echo "There are ${count} compiled kernels in Triton cache."
else
    echo "Triton cache directory doesn't exist."
fi
