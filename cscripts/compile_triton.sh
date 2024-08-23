#!/usr/bin/env bash

export PIP_ROOT_USER_ACTION='ignore'
export TRITON_USE_ROCM='ON'

pip uninstall --yes triton && \
cd /triton_dev/triton/python && \
# FIXME: `--editable` option of `pip install` is causing trouble to `import triton`.
pip install .
