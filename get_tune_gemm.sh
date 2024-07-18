#!/usr/bin/env bash

REPO_URL='https://github.com/ROCm/triton.git'
REPO_BRANCH='triton-mlir'
REPO_TUNE_GEMM_DIR='scripts/amd/gemm'
LOCAL_TUNE_GEMM_DIR='tune_gemm'

git clone --no-checkout --single-branch --branch="${REPO_BRANCH}" --depth=1 \
    "${REPO_URL}" "${LOCAL_TUNE_GEMM_DIR}" &&
git -C "${LOCAL_TUNE_GEMM_DIR}" sparse-checkout set --cone &&
git -C "${LOCAL_TUNE_GEMM_DIR}" checkout "${REPO_BRANCH}" &&
git -C "${LOCAL_TUNE_GEMM_DIR}" sparse-checkout set "${REPO_TUNE_GEMM_DIR}" &&
mv "${LOCAL_TUNE_GEMM_DIR}/${REPO_TUNE_GEMM_DIR}/"* "${LOCAL_TUNE_GEMM_DIR}" &&
rm --recursive --force "${LOCAL_TUNE_GEMM_DIR}/.git"
