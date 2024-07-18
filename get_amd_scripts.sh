#!/usr/bin/env bash

REPO_URL='https://github.com/ROCm/triton.git'
REPO_BRANCH='triton-mlir'
REPO_AMD_SCRIPTS_DIR='scripts/amd'
LOCAL_REPO_DIR='amd_scripts'

git clone --no-checkout --single-branch --branch="${REPO_BRANCH}" --depth=1 \
    "${REPO_URL}" "${LOCAL_REPO_DIR}" &&
git -C "${LOCAL_REPO_DIR}" sparse-checkout set --cone &&
git -C "${LOCAL_REPO_DIR}" checkout "${REPO_BRANCH}" &&
git -C "${LOCAL_REPO_DIR}" sparse-checkout set "${REPO_AMD_SCRIPTS_DIR}"
