#!/usr/bin/env bash
set -euo pipefail

export PIP_ROOT_USER_ACTION=ignore

REPO_PRIMARY='/triton_dev/aiter'
REPO_SECONDARY='/workspace/aiter'
REPO_URL='git@github.com:ROCm/aiter.git'

CLONED=false

# ------------------------------------------------------------------------------
# Locate repository (primary takes precedence)
# ------------------------------------------------------------------------------

if [[ -d "${REPO_PRIMARY}/.git" ]]; then
    AITER_REPO="${REPO_PRIMARY}"
elif [[ -d "${REPO_SECONDARY}/.git" ]]; then
    AITER_REPO="${REPO_SECONDARY}"
else
    echo "AITER repository not found. Cloning into ${REPO_PRIMARY}..."
    mkdir -p "$(dirname "${REPO_PRIMARY}")"
    git clone --recursive "${REPO_URL}" "${REPO_PRIMARY}"
    AITER_REPO="${REPO_PRIMARY}"
    CLONED=true
fi

echo "Using AITER repo at: ${AITER_REPO}"

cd "${AITER_REPO}"

# ------------------------------------------------------------------------------
# Update repository (safe rebase workflow)
# ------------------------------------------------------------------------------

git fetch --all --prune

if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
    OLD_HEAD=$(git rev-parse HEAD)
    git pull --rebase --autostash
    if [[ "${CLONED}" == false && "${OLD_HEAD}" == "$(git rev-parse HEAD)" ]]; then
        echo 'No changes detected. Skipping build.'
        exit 0
    fi
else
    echo 'No upstream branch configured; skipping rebase.'
fi

# ------------------------------------------------------------------------------
# Ensure submodules are up to date
# ------------------------------------------------------------------------------

git submodule sync --recursive
git submodule update --init --recursive

# ------------------------------------------------------------------------------
# Build AITER
# ------------------------------------------------------------------------------

pip uninstall --yes amd-aiter || true
python setup.py develop

# Import AITER as a smoke test.
python -c 'import aiter'
