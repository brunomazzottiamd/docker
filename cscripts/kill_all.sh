#!/usr/bin/env bash

echo "Killing all [${1}] processes..."

for pid in $(pgrep "${1}"); do
    # This `if` statement is to avoid suicide.
    if (( "${pid}" != "${$}" )); then
	echo "Killing PID [${pid}]..."
	kill -9 "${pid}" &> /dev/null &
    fi
done

wait
echo 'Done'
