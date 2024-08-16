FROM rocm/pytorch:rocm6.1.3_ubuntu22.04_py3.10_pytorch_release-2.1.2

### Build time variables:
ARG USER_REAL_NAME
ARG USER_EMAIL
ARG USER_ID
ARG USER_NAME
ARG GROUP_ID
ARG GROUP_NAME

### Image metadata:
LABEL org.opencontainers.image.authors="${USER_EMAIL}" \
      org.opencontainers.image.title="Triton development environment of ${USER_REAL_NAME}."

### Environment variables:
    # No warnings when running `pip` as `root`.
ENV PIP_ROOT_USER_ACTION=ignore \
    # Required for Triton compilation.
    TRITON_USE_ROCM=ON

### apt step:
COPY apt_requirements.txt /tmp
    # Update package index.
RUN apt-get --yes update && \
    # Update packages.
    apt-get --yes upgrade && \
    # Install packages.
    sed 's/#.*//;/^$/d' /tmp/apt_requirements.txt \
        | xargs apt-get --yes install --no-install-recommends && \
    # Clean up apt.
    apt-get --yes autoremove && \
    apt-get clean && \
    rm --recursive --force /tmp/apt_requirements.txt /var/lib/apt/lists/*

### Special build of `aqlprofiler` (it's required to use ATT Viewer):
COPY deb/hsa-amd-aqlprofile_1.0.0-local_amd64.deb /tmp
RUN dpkg --install /tmp/hsa-amd-aqlprofile_1.0.0-local_amd64.deb && \
    rm --recursive --force /tmp/hsa-amd-aqlprofile_1.0.0-local_amd64.deb

### pip step:
COPY pip_requirements.txt /tmp
    # Uninstall Triton shipped with PyTorch, we'll compile Triton from source.
RUN pip uninstall --yes triton && \
    # Install pacakges.
    pip install --no-cache-dir --requirement /tmp/pip_requirements.txt && \
    # Install `hip-python` from TestPyPI package index.
    # (it's required for `tune_gemm.py --icache_flush` option)
    pip install --no-cache-dir --index-url https://test.pypi.org/simple hip-python~=6.1 && \
    # Clean up pip.
    rm --recursive --force /tmp/pip_requirements.txt && \
    pip cache purge

### Configure Git:
RUN git config --global user.name "${USER_REAL_NAME}" && \
    git config --global user.email "${USER_EMAIL}" && \
    # TODO: Configure editor as `editor.sh` script.
    git config --global core.editor 'code --wait' && \
    # Set GitHub SSH hosts as known hosts:
    mkdir --parents --mode 0700 ~/.ssh && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts

### Prepare Triton repository:
WORKDIR /triton_dev/triton
RUN --mount=type=ssh git clone git@github.com:triton-lang/triton.git . && \
    git remote add rocm git@github.com:ROCm/triton.git && \
    git remote add "${USER_NAME}" git@github.com:brunomazzottiamd/triton.git && \
    git fetch --all --prune && \
    git checkout --track rocm/triton-mlir && \
    git checkout --track rocm/main_perf && \
    git checkout main && \
    pre-commit install

### Compile Triton:
WORKDIR /triton_dev/triton/python
RUN pip install --editable .

### Remove build time SSH stuff:
RUN rm --recursive --force ~/.ssh

### Setup user:
# RUN addgroup --system --gid "${GROUP_ID}" "${GROUP_NAME}" && \
#     adduser --system --gid "${GROUP_ID}" --uid "${USER_ID}" "${USER_NAME}" \
#         --home /triton_dev/chome --shell "$(which bash)" && \
#     chown --recursive "${USER_NAME}:${GROUP_NAME}" /triton_dev
# USER "${USER_NAME}"
# FIXME: This step isn't working!
#        User sees Python *3.12.3* from `/opt/conda/bin/python` while `root`
#        sees Python *3.10.14* from `/opt/conda/envs/py_3.10/bin/python`.
#           Possible solution:
#           `conda init && conda activate py_3.10`
#        GPUs aren't visible to the user.
#           Possible solution:
#           `usermod --append --groups render,video "${USER_NAME}"`

### Entrypoint:
WORKDIR /triton_dev
ENTRYPOINT [ "bash" ]

# FIXME: After all, `pip check` reports the following version inconsistencies:
# > numba 0.55.2 has requirement numpy<1.23,>=1.18, but you have numpy 1.26.4.

# `jupyter lab --allow-root --no-browser` runs Jupyter on port 8888.
# TODO: How can we access Jupyter from our development environment?
#       * `-p 8888:8888` argument for `docker run`?
#       * Add `EXPOSE 8888` to `Dockerfile`?
