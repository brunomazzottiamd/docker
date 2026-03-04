#!/usr/bin/env bash
set -euo pipefail

export PIP_ROOT_USER_ACTION=ignore
export TRITON_BUILD_WITH_CCACHE=true

REPO_PRIMARY='/triton_dev/triton'
REPO_SECONDARY='/workspace/triton'
REPO_URL='git@github.com:triton-lang/triton.git'

# ------------------------------------------------------------------------------
# Locate repository (primary takes precedence)
# ------------------------------------------------------------------------------

if [[ -d "${REPO_PRIMARY}/.git" ]]; then
    TRITON_REPO="${REPO_PRIMARY}"
elif [[ -d "${REPO_SECONDARY}/.git" ]]; then
    TRITON_REPO="${REPO_SECONDARY}"
else
    echo "Triton repository not found. Cloning into ${REPO_PRIMARY}..."
    mkdir -p "$(dirname "${REPO_PRIMARY}")"
    git clone "${REPO_URL}" "${REPO_PRIMARY}"
    TRITON_REPO="${REPO_PRIMARY}"
fi

echo "Using Triton repo at: ${TRITON_REPO}"

# ------------------------------------------------------------------------------
# Update repository (safe rebase workflow)
# ------------------------------------------------------------------------------

cd "${TRITON_REPO}"

git fetch --all --prune

if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
    OLD_HEAD=$(git rev-parse HEAD)
    git pull --rebase --autostash
    if [[ "${OLD_HEAD}" == "$(git rev-parse HEAD)" ]]; then
        echo 'No changes detected. Skipping build.'
        exit 0
    fi
else
    echo 'No upstream branch configured; skipping rebase.'
fi

# ------------------------------------------------------------------------------
# Build Triton
# ------------------------------------------------------------------------------

pip uninstall --yes triton || true

pip install --requirement python/requirements.txt
pip install --verbose --no-build-isolation --editable .

# Run vector add tutorial as a smoke test.
python python/tutorials/01-vector-add.py
