#!/usr/bin/env bash

### User information:

export USER_REAL_NAME='Bruno Mazzotti'
export USER_EMAIL='bruno.mazzotti@amd.com'

USER_ID=$(id --user)
export USER_ID
USER_NAME=$(id --user --name)
export USER_NAME

GROUP_ID=$(id --group)
export GROUP_ID
GROUP_NAME=$(id --group --name)
export GROUP_NAME


### Image / container information:

export TRITON_DEV_NAME='triton_dev'
export IMAGE_NAME="${USER_NAME}_${TRITON_DEV_NAME}"
