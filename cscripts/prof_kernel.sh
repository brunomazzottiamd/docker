#!/usr/bin/env bash


### Helper functions

trim_string() {
    : "${1#"${1%%[![:space:]]*}"}"
    : "${_%"${_##*[![:space:]]}"}"
    printf '%s\n' "$_"
}

remove() {
    rm --recursive --force "${@}"
}


### Profiling functions

function prof_kernel() {
    num_executions="${1}"
    shift
    regex="${1}"
    shift
    output_csv_file="${1}"
    shift
    echo 'kernel_name,duration_ns' > "${output_csv_file}"
    echo "Running [ ${num_executions} ] rocprof executions:"
    for ((i = 0; i < num_executions; ++i)); do
	echo -n '.'
	rocprof --stats "${@}" &> /dev/null
	grep "${regex}" results.stats.csv \
	    | cut --delimiter=',' --fields=1,3 \
	    >> "${output_csv_file}"
	remove results.*
    done
    echo
}

function compute_stats() {
    input_csv_file="${1}"
    output_csv_file="${2}"
    echo 'Statistics:'
    python << EOF
import pandas as pd
df = pd.read_csv("${input_csv_file}")
df["duration_us"] = df["duration_ns"] / 10**3
df.drop(columns=["duration_ns"], inplace=True)
trim_percent = 0.2  # Adjust the trimming percentage (20%)
def trimmed_stats(x):
    x = x.sort_values().iloc[int(len(x) * trim_percent) : int(len(x) * (1 - trim_percent))]
    return pd.Series({"mean_us": x.mean(), "std_us": x.std(ddof=0)})
df = df.groupby("kernel_name")["duration_us"].apply(trimmed_stats).unstack().reset_index()
df.to_csv("${output_csv_file}", index=False)
print(df.to_markdown(index=False))
EOF
}


### Command line parsing

usage() {
    echo "Usage: ${0} -r kernel_regex [ -o output_dir ] -- kernel_program [ kernel_program_args... ]"
    exit 1
}

kernel_regex=""
output_dir=""
kernel_program=()

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -r|--kernel-regex)
            kernel_regex="${2}"
            shift 2
            ;;
        -o|--output)
            output_dir="${2}"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -h|--help|*)
            usage
            ;;
    esac
done

# Set kernel regex.
kernel_regex=$(trim_string "${kernel_regex}")
if [ -z "${kernel_regex}" ]; then
    echo "Error: Kernel regex (--kernel-regex / -r) is required."
    usage
fi

# Set output directory.
output_dir=$(trim_string "${output_dir}")
if [ -z "${output_dir}" ]; then
    # Use a sensible default as output directory.
    output_dir=$(date "+${kernel_regex}_prof_data_%Y-%m-%d-%H-%M-%S")
fi

# Set kernel program.
if [ "${#}" -eq 0 ]; then
    echo "Error: No kernel program provided after --."
    usage
fi
for kernel_program_item in "${@}"; do
    kernel_program_item=$(trim_string "${kernel_program_item}")
    if [ -n "${kernel_program_item}" ]; then
        kernel_program+=("${kernel_program_item}")
    fi
done


### Start kernel profiling script

echo 'PROFILING KERNEL...'
echo "Kernel regex is [ ${kernel_regex} ]."
echo "Output directory is [ ${output_dir} ]."
echo 'Kernel program is [' "${kernel_program[@]}" '].'


### Cleanup older files from previous runs

echo 'Cleaning older files from previous runs...'
remove "${output_dir}"


### Create new empty output directory

echo "Creating new empty output directory [ ${output_dir} ]..."
mkdir --parents "${output_dir}"


### Profile

num_executions=25
prof_data_file="${output_dir}/prof_data.csv"
prof_stats_file="${output_dir}/prof_stats.csv"

prof_kernel "${num_executions}" "${kernel_regex}" "${prof_data_file}" "${kernel_program[@]}"

compute_stats "${prof_data_file}" "${prof_stats_file}"


### Done

echo 'DONE.'
