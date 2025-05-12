#!/usr/bin/env bash

triton_cache_dir="${HOME}/.triton/cache"

if [ -d "${triton_cache_dir}" ]; then
    count=$(find "${triton_cache_dir}" -type f -name '*.amdgcn' | wc --lines)
    size=$(du --summarize --human-readable "${triton_cache_dir}" | cut --fields=1)
    if [ "${count}" -eq 0 ]; then
	echo "Triton cache is empty (${size})."
    elif [ "${count}" -eq 1 ]; then
	echo "There is 1 compiled kernel in Triton cache (${size})."
    elif [ "${count}" -gt 1 ]; then
	echo "There are ${count} compiled kernels in Triton cache (${size})."
    else
	echo 'The number of compiled Triton kernels is negative, this is unexpected.'
    fi
else
    echo "Triton cache directory doesn't exist."
fi
