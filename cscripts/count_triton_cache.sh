#!/usr/bin/env bash

triton_cache_dir="${HOME}/.triton/cache"

if [ -d "${triton_cache_dir}" ]; then
    ttir_count=$(find "${triton_cache_dir}" -type f -name '*.ttir' | wc --lines)
    ttgir_count=$(find "${triton_cache_dir}" -type f -name '*.ttgir' | wc --lines)
    llir_count=$(find "${triton_cache_dir}" -type f -name '*.llir' | wc --lines)
    amdgcn_count=$(find "${triton_cache_dir}" -type f -name '*.amdgcn' | wc --lines)
    hsaco_count=$(find "${triton_cache_dir}" -type f -name '*.hsaco' | wc --lines)
    size=$(du --summarize --human-readable "${triton_cache_dir}" | cut --fields=1)
    avail_size=$(df --output=avail --human-readable "${triton_cache_dir}" | tail -1 | tr --delete ' ')

    if [ "${hsaco_count}" -eq 0 ]; then
	echo 'There is no fully compiled kernel in Triton cache.'
    elif [ "${hsaco_count}" -eq 1 ]; then
	echo 'There is 1 fully compiled kernel in Triton cache.'
    elif [ "${hsaco_count}" -gt 1 ]; then
	echo "There are ${hsaco_count} fully compiled kernels in Triton cache."
    else
	echo 'The number of compiled Triton kernels is negative, this is unexpected!'
    fi

    msg="(${ttir_count} TTIR, ${ttgir_count} TTGIR, ${llir_count} LLIR, ${amdgcn_count} AMDGCN, ${hsaco_count} HSACO, cache size ${size}, available size ${avail_size})"
    echo "${msg}"

else
    echo "Triton cache directory doesn't exist."
fi
