#!/usr/bin/env bash

code --wait "${@}" 2> /dev/null || emacs --no-window-system "${@}"
