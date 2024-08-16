#!/usr/bin/env python

# -*- coding: utf-8 -*-

import argparse
import sys

import pandas as pd


def parse_args():
    parser = argparse.ArgumentParser(description="convert CSV file to Markdown")
    parser.add_argument(
        "-i",
        "--input",
        required=True,
        help="mandatory input CSV file",
    )
    default_output = "-"
    parser.add_argument(
        "-o",
        "--output",
        default=default_output,
        help=f"output Markdown, can be a file or - for standard output (defaults to {default_output})",
    )
    return parser.parse_args()


def csv_to_markdown(csv_input_file, markdown_output):
    markdown_content = pd.read_csv(csv_input_file).to_markdown(index=False)
    with (sys.stdout
          if markdown_output == "-" else open(markdown_output, "w", encoding="utf-8")) as markdown_output_file:
        print(markdown_content, file=markdown_output_file)


if __name__ == "__main__":
    args = parse_args()
    csv_to_markdown(args.input, args.output)
