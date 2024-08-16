#!/usr/bin/env python

# -*- coding: utf-8 -*-

import argparse

import pandas as pd


def parse_args():
    parser = argparse.ArgumentParser(description="convert benchmarking results from TFLOPS to GiBps", )
    parser.add_argument(
        "-i",
        "--input",
        required=True,
        help="mandatory input CSV file (must have columns M, N, K, TFLOPS and us)",
    )
    default_output_file = "output.csv"
    parser.add_argument(
        "-o",
        "--output",
        default=default_output_file,
        help=f"output CSV file (defaults to {default_output_file})",
    )
    default_bytes_per_elem = 2
    parser.add_argument(
        "-b",
        "--bytes-per-elem",
        type=int,
        choices=[1, 2, 4, 8],
        default=default_bytes_per_elem,
        help=f"number of bytes per matrix element (defaults to {default_bytes_per_elem})",
    )
    return parser.parse_args()


def convert_tflops_to_gibps(input_file, output_file, bytes_per_elem):
    df = pd.read_csv(input_file)

    df.drop("TFLOPS", axis="columns", inplace=True)

    M = df["M"]
    N = df["N"]
    K = df["K"]
    read_elems = M * K + K * N
    write_elems = M * N
    transf_elems = read_elems + write_elems
    transf_bytes = bytes_per_elem * transf_elems
    transf_gibibytes = 2**-30 * transf_bytes

    microseconds = df["us"]
    seconds = 1e-6 * microseconds

    gibibytes_per_second = (transf_gibibytes / seconds).round(2)
    df["GiBps"] = gibibytes_per_second

    df.to_csv(output_file, index=False)


if __name__ == "__main__":
    args = parse_args()
    convert_tflops_to_gibps(args.input, args.output, args.bytes_per_elem)
