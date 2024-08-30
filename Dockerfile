FROM rocm/pytorch:rocm6.2_ubuntu22.04_py3.10_pytorch_release_2.3.0

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
ENV PIP_ROOT_USER_ACTION=ignore

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
COPY deb/rocm6.2_hsa-amd-aqlprofile_1.0.0-local_amd64.deb /tmp
RUN dpkg --install /tmp/rocm6.2_hsa-amd-aqlprofile_1.0.0-local_amd64.deb && \
    rm --recursive --force /tmp/rocm6.2_hsa-amd-aqlprofile_1.0.0-local_amd64.deb

### pip step:
COPY pip_requirements.txt /tmp
    # Uninstall Triton shipped with PyTorch, we'll compile Triton from source.
RUN pip uninstall --yes triton && \
    # Install pacakges.
    pip install --no-cache-dir --requirement /tmp/pip_requirements.txt && \
    # Install `hip-python` from TestPyPI package index.
    # (it's required for `tune_gemm.py --icache_flush` option)
    pip install --no-cache-dir --index-url https://test.pypi.org/simple hip-python~=6.2 && \
    # Clean up pip.
    rm --recursive --force /tmp/pip_requirements.txt && \
    pip cache purge

### Setup user:
    # Create group.
RUN addgroup --system --gid "${GROUP_ID}" "${GROUP_NAME}" && \
    # Create user.
    adduser --system --gid "${GROUP_ID}" --uid "${USER_ID}" "${USER_NAME}" \
        --home /triton_dev/chome --shell "$(which bash)" && \
    # Add user to special groups so GPU is accessible.
    usermod --append --groups render,video "${USER_NAME}"
USER "${USER_NAME}"
    # Set GitHub SSH hosts as known hosts:
RUN mkdir --parents --mode 0700 /triton_dev/chome/.ssh && \
    ssh-keyscan github.com >> /triton_dev/chome/.ssh/known_hosts && \
    # Setup Anaconda environment:
    conda init bash && \
    echo 'conda activate py_3.10' >> /triton_dev/chome/.bashrc

### Configure Git:
RUN git config --global user.name "${USER_REAL_NAME}" && \
    git config --global user.email "${USER_EMAIL}" && \
    # `editor.sh` is in `cscripts`, see next step for more details.
    git config --global core.editor /triton_dev/docker/cscripts/editor.sh

### Get useful scripts from personal Docker repository:
WORKDIR /triton_dev/docker
    # Clone repository:
RUN --mount=type=ssh,uid="${USER_ID}",gid="${GROUP_ID}" \
    git clone --no-checkout git@github.com:brunomazzottiamd/docker.git . && \
    # Sparse checkout only `cscripts` directory:
    git sparse-checkout set --cone && \
    git checkout main && \
    git sparse-checkout set cscripts && \
    # Add `cscripts` to `PATH`:
    echo 'export PATH="${PATH}:/triton_dev/docker/cscripts"' >> /triton_dev/chome/.bashrc

### Prepare Triton repository:
WORKDIR /triton_dev/triton
    # Clone repository:
RUN --mount=type=ssh,uid="${USER_ID}",gid="${GROUP_ID}" \
    git clone git@github.com:triton-lang/triton.git . && \
    # Add remotes of interest:
    git remote add rocm git@github.com:ROCm/triton.git && \
    git remote add "${USER_NAME}" git@github.com:brunomazzottiamd/triton.git && \
    git fetch --all --prune && \
    # Checkout branches of interest:
    git checkout --track rocm/triton-mlir && \
    git checkout --track rocm/main_perf && \
    git checkout main && \
    # Install pre-commit hooks:
    pre-commit install && \
    # Do a "fake commit" to initialize `pre-commit` framework, it takes some
    # time and it's an annoying process...
    git add $(mktemp --tmpdir=.) && \
    git commit --allow-empty-message --message '' && \
    git reset --hard HEAD~

### Compile Triton:
WORKDIR /triton_dev/triton/python
    # FIXME: `--editable` option of `pip install` is causing trouble to `import triton`.
RUN pip install --verbose .

### Remove build time SSH stuff:
RUN rm --recursive --force ~/.ssh

### Entrypoint:
WORKDIR /triton_dev
ENTRYPOINT [ "bash" ]
