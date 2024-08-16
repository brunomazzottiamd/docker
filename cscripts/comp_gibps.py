#!/usr/bin/env python

# -*- coding: utf-8 -*-

import argparse

import pandas as pd

GIBPS_COL_NAME = "GiBps"


def parse_args():
    parser = argparse.ArgumentParser(description="compare benchmarking results in GiBps", )
    parser.add_argument(
        "-r",
        "--reference",
        required=True,
        help=f"mandatory reference input CSV file (must have {GIBPS_COL_NAME} column)",
    )
    parser.add_argument(
        "-c",
        "--candidate",
        required=True,
        help=f"mandatory candidate input CSV file (must have {GIBPS_COL_NAME} column)",
    )
    default_output_file = "output.csv"
    parser.add_argument(
        "-o",
        "--output",
        default=default_output_file,
        help=f"output CSV file (defaults to {default_output_file})",
    )
    return parser.parse_args()


def read_data(input_file, gibps_col_name=GIBPS_COL_NAME):
    df = pd.read_csv(input_file)
    other = df.loc[:, df.columns != gibps_col_name]
    gibps = df[gibps_col_name]
    return other, gibps


def compare_gibps(ref_input_file, cand_input_file, output_file):
    ref_other, ref_gibps = read_data(ref_input_file)
    cand_other, cand_gibps = read_data(cand_input_file)
    out = pd.concat(
        [
            ref_other[ref_other == cand_other].dropna(axis=1),
            ref_gibps.rename(f"reference_{GIBPS_COL_NAME}"),
            cand_gibps.rename(f"candidate_{GIBPS_COL_NAME}"),
            (cand_gibps / ref_gibps).round(2).rename("speedup"),
        ],
        axis=1,
    )
    out.to_csv(output_file, index=False)


if __name__ == "__main__":
    args = parse_args()
    compare_gibps(args.reference, args.candidate, args.output)
