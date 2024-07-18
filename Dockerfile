FROM rocm/pytorch:rocm6.1.3_ubuntu22.04_py3.10_pytorch_release-2.1.2

### Image metadata:
LABEL org.opencontainers.image.authors='bruno.mazzotti@amd.com' \
      org.opencontainers.image.title='Triton development environment of Bruno Mazzotti.'

### Environment variables:
    # No warnings when running `pip` as `root`.
ENV PIP_ROOT_USER_ACTION=ignore \
    # Required for Triton compilation.
    TRITON_USE_ROCM=ON

### apt step:
    # Update package index.
RUN apt-get --yes update && \
    # Update packages.
    apt-get --yes upgrade && \
    # Install my stuff.
    apt-get --yes install --no-install-recommends \
        less \
        tree \
        htop \
        shellcheck \
        emacs \
        && \
    # Clean up apt.
    apt-get --yes autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

### pip step:
    # Uninstall Triton shipped with PyTorch, we'll compile Triton from source.
RUN pip uninstall --yes triton && \
    # Install my stuff.
    pip install --no-cache-dir \
        pipdeptree \
        ipython \
        jupyterlab \
        black \
        'black[jupyter]' \
        jupyter-black \
        && \
    # Install Triton stuff.
    # Using latest NumPy from 1.0 series.
    pip install --no-cache-dir \
        numpy==1.26.4 \
        scipy \
        pandas \
        matplotlib \
        tabulate \
        pytest \
        pre-commit \
        lit \
        && \
    # Clean up pip.
    pip cache purge

### Prepare Triton repository:
WORKDIR /triton
RUN git config --global user.name 'Bruno Mazzotti' && \
    git config --global user.email 'bruno.mazzotti@amd.com' && \
    git config --global core.editor 'code --wait' && \
    git clone https://github.com/triton-lang/triton . && \
    git remote add rocm https://github.com/ROCm/triton.git && \
    git remote add bruno https://github.com/brunomazzottiamd/triton.git && \
    git fetch --all && \
    pre-commit install

### Compile Triton:
WORKDIR /triton/python
RUN pip install --editable .

### Entrypoint:
WORKDIR /triton
ENTRYPOINT [ "bash" ]

# FIXME: After all, `pip check` reports the following version inconsistencies:
# > numba 0.55.2 has requirement numpy<1.23,>=1.18, but you have numpy 1.26.4.

# `jupyter lab --allow-root --no-browser` runs Jupyter on port 8888.
# TODO: How can we access Jupyter from our development environment?
#       * `-p 8888:8888` argument for `docker run`?
#       * Add `EXPOSE 8888` to `Dockerfile`?
