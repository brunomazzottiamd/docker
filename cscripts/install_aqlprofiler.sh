#!/usr/bin/env bash

# Install special build of `aqlprofiler`, which is required to get ATT traces.

deb_pkg='/triton_dev/docker/deb/rocm6.3_hsa-amd-aqlprofile_1.0.0-local_amd64.deb'
dpkg --install "${deb_pkg}"
