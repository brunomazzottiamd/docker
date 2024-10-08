#!/usr/bin/env bash

# The special build of `aqlprofiler`, which is required to get ATT traces, breaks
# `apt`. It should be uninstalled to make `apt` functional again.

dpkg --purge --force-all hsa-amd-aqlprofile

apt --yes --fix-broken install
