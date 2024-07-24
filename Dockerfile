FROM rocm/pytorch:rocm6.1.3_ubuntu22.04_py3.10_pytorch_release-2.1.2

### Build time variables:
ARG USER_REAL_NAME
ARG USER_EMAIL
ARG USER_ID
ARG USER_NAME
ARG GROUP_ID
ARG GROUP_NAME
ARG TRITON_DEV_DIR
ARG HOME_DIR
ARG TRITON_REPO_DIR

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

### pip step:
COPY pip_requirements.txt /tmp
    # Uninstall Triton shipped with PyTorch, we'll compile Triton from source.
RUN pip uninstall --yes triton && \
    # Install pacakges.
    pip install --no-cache-dir --requirement /tmp/pip_requirements.txt && \
    # Clean up pip.
    rm --recursive --force /tmp/pip_requirements.txt && \
    pip cache purge

### Configure Git:
RUN git config --global user.name "${USER_REAL_NAME}" && \
    git config --global user.email "${USER_EMAIL}" && \
    # TODO: Configure editor as `editor.sh` script.
    git config --global core.editor 'code --wait'

### Prepare Triton repository:
WORKDIR "${TRITON_REPO_DIR}"
RUN git clone https://github.com/triton-lang/triton . && \
    git remote add rocm https://github.com/ROCm/triton.git && \
    git remote add "${USER_NAME}" https://github.com/brunomazzottiamd/triton.git && \
    git fetch --all && \
    pre-commit install

### Compile Triton:
WORKDIR "${TRITON_REPO_DIR}/python"
RUN pip install --editable .

### Setup user:
# RUN addgroup --system --gid "${GROUP_ID}" "${GROUP_NAME}" && \
#     adduser --system --gid "${GROUP_ID}" --uid "${USER_ID}" "${USER_NAME}" \
#         --home "${HOME_DIR}" --shell "$(which bash)" && \
#     chown --recursive "${USER_NAME}:${GROUP_NAME}" "${TRITON_DEV_DIR}"
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
WORKDIR "${TRITON_DEV_DIR}"
ENTRYPOINT [ "bash" ]

# FIXME: After all, `pip check` reports the following version inconsistencies:
# > numba 0.55.2 has requirement numpy<1.23,>=1.18, but you have numpy 1.26.4.

# `jupyter lab --allow-root --no-browser` runs Jupyter on port 8888.
# TODO: How can we access Jupyter from our development environment?
#       * `-p 8888:8888` argument for `docker run`?
#       * Add `EXPOSE 8888` to `Dockerfile`?
