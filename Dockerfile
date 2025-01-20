FROM rocm/pytorch:rocm6.2.3_ubuntu22.04_py3.10_pytorch_release_2.3.0

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

### Configure Git:
RUN git config --global user.name "${USER_REAL_NAME}" && \
    git config --global user.email "${USER_EMAIL}" && \
    # `editor.sh` is in `cscripts`, see next step for more details.
    git config --global core.editor /triton_dev/docker/cscripts/editor.sh && \
    # Set GitHub SSH hosts as known hosts:
    mkdir --parents --mode 0700 ~/.ssh && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts

### Get useful scripts from personal Docker repository:
WORKDIR /triton_dev/docker
    # Clone repository:
RUN --mount=type=ssh git clone git@github.com:brunomazzottiamd/docker.git . && \
    # Source aliases and environment variables:
    echo 'source /triton_dev/docker/cscripts/bashrc.sh' >> ~/.bashrc && \
    # Source Emacs configuration:
    echo '(load-file "/triton_dev/docker/cscripts/emacs.el")' >> ~/.emacs

### Prepare Triton repository:
WORKDIR /triton_dev/triton
    # Clone repository:
RUN --mount=type=ssh git clone git@github.com:triton-lang/triton.git . && \
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
RUN /triton_dev/docker/cscripts/compile_triton.sh

### Get flash attention repository:
WORKDIR /triton_dev/flash-attention
RUN --mount=type=ssh git clone git@github.com:Dao-AILab/flash-attention.git . && \
    git remote add rocm git@github.com:ROCm/flash-attention.git && \
    git remote add "${USER_NAME}" git@github.com:brunomazzottiamd/flash-attention.git && \
    git fetch --all --prune && \
    git checkout --track rocm/main_perf && \
    git checkout main

### Remove build time SSH stuff:
RUN rm --recursive --force ~/.ssh

### Entrypoint:
WORKDIR /triton_dev
ENTRYPOINT [ "bash" ]
