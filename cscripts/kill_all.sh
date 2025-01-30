#!/usr/bin/env bash

# Avoid suicide, fratricide and killing init.
do_not_kill_pid_list=("${$}" "${PPID}" 1)

echo "Killing all [${1}] processes..."

for pid in $(pgrep "${1}"); do
    kill_pid=1
    for do_not_kill_pid in "${do_not_kill_pid_list[@]}"; do
	if [[ "${pid}" = "${do_not_kill_pid}" ]]; then
	    kill_pid=0
	    break
	fi
    done
    if [[ "${kill_pid}" = 1 ]]; then
	echo "Killing PID [${pid}]..."
	kill -9 "${pid}" &> /dev/null &
    fi
done

wait
echo 'Done'
