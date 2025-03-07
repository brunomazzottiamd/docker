#!/usr/bin/env bash

# Pipeline explanation:
# - send `rocm-smi` output to stdout and stderr
# - remove header
# - remove footer
# - squeeze repeated spaces
# - select Device (field 1), VRAM% (field 15) and GPU% (field 16)
# - remove `%` signs
# - select Devices other than 0 (Device 0 is the default one, it's usually the most used)
# - sort by GPU% (ascending), VRAM% (ascending), Device (descending)
# - pick first line of the sorted data
# - pick Device of first line, it's the chosen GPU!
gpu=$(rocm-smi \
    | tee /dev/stderr \
    | tail --lines +8 \
    | head --lines -2 \
    | tr --squeeze-repeats ' ' \
    | cut --delimiter ' ' --fields 1,15,16 \
    | tr --delete '%' \
    | grep --invert-match '^0 .*$' \
    | sort --key=3,3n --key=2,2n --key=1,1nr \
    | head --lines 1 \
    | cut --delimiter ' ' --fields 1)

echo -e "\nPicked GPU ${gpu}."
export HIP_VISIBLE_DEVICES="${gpu}"
