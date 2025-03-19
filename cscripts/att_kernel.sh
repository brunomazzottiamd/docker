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
    kernel_name="${3}"
    triton_cache_dir="${4}"
    output_dir="${5}"
    echo "Getting kernel ${kernel_file_desc}..."
    kernel_file=$(find "${triton_cache_dir}" -name "${kernel_name}.${kernel_file_ext}" -print -quit)
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

copy_kernel_file 'Triton IR' 'ttir' "${kernel_name}" "${triton_cache_dir}" "${output_dir}"
copy_kernel_file 'Triton GPU IR' 'ttgir' "${kernel_name}" "${triton_cache_dir}" "${output_dir}"
copy_kernel_file 'assembly' 'amdgcn' "${kernel_name}" "${triton_cache_dir}" "${output_dir}"


### Create rocprofv2 input file

echo 'Creating rocprofv2 input file...'

rocprofv2_input_file=$(mktemp --quiet)

# TODO: Add performance counters:
#       PERFCOUNTER=SQ_LDS_DATA_FIFO_FULL
#       PERFCOUNTER=SQ_LDS_CMD_FIFO_FULL
cat << EOF >> "${rocprofv2_input_file}"
att: TARGET_CU=0
SE_MASK=0xFFF
SIMD_SELECT=0xF
ISA_CAPTURE_MODE=2
DISPATCH=${dispatch_id}
PERFCOUNTERS_CTRL=0x2
PERFCOUNTER=SQ_LDS_UNALIGNED_STALL
PERFCOUNTER=SQ_LDS_BANK_CONFLICT
EOF

echo 'rocprofv2 input file content is:'
cat "${rocprofv2_input_file}"


### Generate kernel execution trace

echo 'Generating kernel execution trace...'

clean_triton_cache

# TODO: Add custom metrics file:
# rocprofv2 option -m "${metrics_file}"
# <gfx940>
#   <metric name="SQ_LDS_DATA_FIFO_FULL" block=SQ event=136 descr="SQ_PERF_SEL_LDS_DATA_FIFO_FULL"></metric>
#   <metric name="SQ_LDS_CMD_FIFO_FULL" block=SQ event=137 descr="SQ_PERF_SEL_LDS_CMD_FIFO_FULL"></metric>
rocprofv2 \
    --input "${rocprofv2_input_file}" \
    --plugin att auto \
    --mode file \
    --output-directory "${output_dir}" \
    "${kernel_program[@]}"

# Remove large files, keep only the parsed ATT.
remove "${output_dir}"/*.out "${output_dir}"/*.att "${output_dir}"/*.txt


### Compress output directory
# It's easier to transfer a single file!

echo "Compressing output directory to [${output_xz}]..."

compression_level='7'
tar \
    -cf "${output_xz}" \
    -I "xz -${compression_level}" \
    "${output_dir}"

du \
    --summarize \
    --human-readable \
    "${output_xz}"


### Cleanup intermediate files

echo 'Cleaning intermediate files...'
remove "${rocprofv2_input_file}" "${output_dir}"


### Done

echo 'DONE.'
