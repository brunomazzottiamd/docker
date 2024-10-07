#!/usr/bin/env python

# -*- coding: utf-8 -*-


import argparse

import pandas as pd


def add_bytes_per_elem_arg(parser: argparse.ArgumentParser, matrix: str) -> None:
    default_bytes_per_elem: int = 2
    parser.add_argument(
        f"-b{matrix.lower()}",
        f"--bytes-per-{matrix.lower()}-elem",
        type=int,
        choices=[1, 2, 4, 8],
        default=default_bytes_per_elem,
        help=f"number of bytes per element of matrix {matrix.upper()} (defaults to {default_bytes_per_elem})",
    )


def parse_args() -> argparse.Namespace:
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="convert C = A * B GEMM benchmarking results from TFLOPS to GiBps",
    )
    parser.add_argument(
        "-i",
        "--input",
        required=True,
        help="mandatory CSV input file (must have columns M, N, K, TFLOPS and us)",
    )
    default_output_file: str = "output.csv"
    parser.add_argument(
        "-o",
        "--output",
        default=default_output_file,
        help=f"output CSV file (defaults to {default_output_file})",
    )
    add_bytes_per_elem_arg(parser, "A")
    add_bytes_per_elem_arg(parser, "B")
    add_bytes_per_elem_arg(parser, "C")
    return parser.parse_args()


def convert_tflops_to_gibps(
    input_file: str,
    output_file: str,
    bytes_per_a_elem: int,
    bytes_per_b_elem: int,
    bytes_per_c_elem: int,
) -> None:
    assert input_file
    assert output_file
    assert bytes_per_a_elem > 0
    assert bytes_per_b_elem > 0
    assert bytes_per_c_elem > 0

    df: pd.DataFrame = pd.read_csv(input_file)
    df.drop("TFLOPS", axis="columns", inplace=True)

    M: pd.Series = df["M"]
    N: pd.Series = df["N"]
    K: pd.Series = df["K"]
    assert (M > 0).all()
    assert (N > 0).all()
    assert (K > 0).all()

    read_A_bytes: pd.Series = bytes_per_a_elem * M * K
    read_B_bytes: pd.Series = bytes_per_b_elem * K * N
    write_C_bytes: pd.Series = bytes_per_c_elem * M * N
    transf_bytes: pd.Series = read_A_bytes + read_B_bytes + write_C_bytes
    transf_gibibytes: pd.Series = 2**-30 * transf_bytes

    microseconds: pd.Series = df["us"]
    seconds: pd.Series = 1e-6 * microseconds

    gibibytes_per_second: pd.Series = (transf_gibibytes / seconds).round(2)
    df["GiBps"] = gibibytes_per_second

    df.to_csv(output_file, index=False)


def main() -> None:
    args: argparse.Namespace = parse_args()
    convert_tflops_to_gibps(
        args.input,
        args.output,
        args.bytes_per_a_elem,
        args.bytes_per_b_elem,
        args.bytes_per_c_elem,
    )


if __name__ == "__main__":
    main()
