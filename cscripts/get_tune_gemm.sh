#!/usr/bin/env bash

repo_url='https://github.com/ROCm/triton.git'
repo_branch='main_perf'
repo_dir='python/perf-kernels/tools/tune_gemm'
local_dir='tune_gemm'

while getopts ':r:b:d:l:' option; do
    case "${option}" in
        r)
            repo_url="${OPTARG}"
            ;;
        b)
            repo_branch="${OPTARG}"
            ;;
        d)
            repo_dir="${OPTARG}"
            ;;
        l)
            local_dir="${OPTARG}"
            ;;
        :)
            echo "Option -${OPTARG} requires an argument."
            exit 1
            ;;
        ?)
            echo "Invalid option: -${OPTARG}."
            exit 1
            ;;
    esac
done

local_dir=$(realpath "${local_dir}")

echo "\
Getting *tune_gemm* script from:
* Git repository: ${repo_url}
* Repository branch: ${repo_branch}
* Branch directory: ${repo_dir}
Saving *tune_gemm* script to:
* Local directory: ${local_dir}"

if [ -e "${local_dir}" ]; then
    echo "Local directory already exists. It must be non-existent for successful cloning."
    exit 1
fi

git clone --no-checkout --single-branch --branch="${repo_branch}" --depth=1 \
    "${repo_url}" "${local_dir}" &&
git -C "${local_dir}" sparse-checkout set --cone &&
git -C "${local_dir}" checkout "${repo_branch}" &&
git -C "${local_dir}" sparse-checkout set "${repo_dir}" &&
mv "${local_dir}/${repo_dir}"/* "${local_dir}" &&
rm --recursive --force "${local_dir}/.git" &&
exit 0
