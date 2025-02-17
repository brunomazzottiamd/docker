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

copy_kernel_file() {
    kernel_file_desc="${1}"
    kernel_file_ext="${2}"
    triton_cache_dir="${3}"
    output_dir="${4}"
    echo "Getting kernel ${kernel_file_desc}..."
    kernel_file=$(find "${triton_cache_dir}" -name "*.${kernel_file_ext}" | head -1)
    echo "Kernel ${kernel_file_desc} is [ ${kernel_file} ]."
    cp "${kernel_file}" "${output_dir}"
}

triton_cache_dir="${HOME}/.triton/cache"

clean_triton_cache() {
    echo "Cleaning Triton cache at [ ${triton_cache_dir} ]..."
    remove "${triton_cache_dir}"
}


### Command line parsing

usage() {
    echo "Usage: ${0} -n kernel_name [ -o output_dir ] -- kernel_program [ kernel_program_args... ]"
    exit 1
}

kernel_name=""
output_dir=""
kernel_program=()
python_source=""

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n|--kernel-name)
            kernel_name="${2}"
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

# Set kernel name.
kernel_name=$(trim_string "${kernel_name}")
if [ -z "${kernel_name}" ]; then
    echo "Error: Kernel name (--kernel-name / -n) is required."
    usage
fi

# Set output directory and compressed output file.
output_dir=$(trim_string "${output_dir}")
if [ -z "${output_dir}" ]; then
    # Use a sensible default as output directory.
    output_dir=$(date "+${kernel_name}_prof_data_%Y-%m-%d-%H-%M-%S")
fi
output_xz="$(basename "${output_dir}").tar.xz"

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

# Set Python source.
for kernel_program_item in "${kernel_program[@]}"; do
    if [[ "${kernel_program_item}" == *.py ]]; then
        python_source="${kernel_program_item}"
        break
    fi
done


### Start kernel profiling script

echo 'PROFILING TRITON KERNEL...'
echo "Kernel name is [ ${kernel_name} ]."
echo "Output directory is [ ${output_dir} ]. It'll be compressed to [ ${output_xz} ]."
echo 'Kernel program is [' "${kernel_program[@]}" '].'
if [ -z "${python_source}" ]; then
    echo 'No Python source found in kernel program, the kernel profiling script will not be able to collect it.'
else
    echo "Python source is [ ${python_source} ]."
fi


### Cleanup older files from previous runs

echo 'Cleaning older files from previous runs...'
remove "${output_dir}" "${output_xz}"


### Create new empty output directory

echo "Creating new empty output directory [ ${output_dir} ]..."
mkdir --parents "${output_dir}"


### Get kernel dispatch ID

echo 'Getting kernel dispatch ID...'

clean_triton_cache

dispatch_id=$(rocprofv2 \
    "${kernel_program[@]}" \
    | grep --max-count=1 "${kernel_name}" \
    | cut --delimiter ',' --fields 1 \
    | sed 's/Dispatch_ID(//;s/)//'
)

echo "Kernel dispatch ID is [ ${dispatch_id} ]."


### Get kernel IRs and assembly code

copy_kernel_file 'Triton IR' 'ttir' "${triton_cache_dir}" "${output_dir}"
copy_kernel_file 'Triton GPU IR' 'ttgir' "${triton_cache_dir}" "${output_dir}"
copy_kernel_file 'assembly' 'amdgcn' "${triton_cache_dir}" "${output_dir}"
