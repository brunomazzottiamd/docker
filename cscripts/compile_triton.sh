#!/usr/bin/env bash

export PIP_ROOT_USER_ACTION=ignore
export TRITON_BUILD_WITH_CCACHE=true

pip uninstall --yes triton && \
cd /triton_dev/triton && \
pip install --requirement python/requirements.txt && \
pip install --verbose --no-build-isolation --editable .
