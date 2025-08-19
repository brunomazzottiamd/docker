#!/usr/bin/env bash

export PIP_ROOT_USER_ACTION=ignore

pip uninstall --yes aiter && \
cd /triton_dev/aiter && \
python setup.py develop
