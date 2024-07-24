#!/usr/bin/env bash

code --wait "${@}" || emacs --no-window-system "${@}"
