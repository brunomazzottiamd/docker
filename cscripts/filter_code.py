#!/usr/bin/env python

# -*- coding: utf-8 -*-

# pylint: disable=missing-docstring


import argparse
import csv
import json
import logging
import re
from dataclasses import dataclass
from typing import Any, Optional

FILTER_STR_FORMAT: str = (
    "source_file:[exact_line_number|start_line_number-end_line_number]"
)


@dataclass
class SourceLocation:
    source_file: str
    line_number: int


@dataclass
class CodeLine:
    instruction: str
    source_location: SourceLocation
    sum_all: int


@dataclass
class SourceLocationFilter:
    source_file_filter: str
    line_number_filter: int | tuple[int, int]


def get_instruction(instruction: str) -> Optional[str]:
    if instruction:
        instruction = instruction.strip()
    if not instruction or instruction.startswith(";"):
        logging.info("Ignoring empty instruction or comment.")
        return None
    return instruction


def get_source_location(source_location: str) -> Optional[SourceLocation]:
    if not source_location:
        logging.info("Ignoring empty source location.")
        return None
    split_source_location: list[str] = source_location.split(":")
    if len(split_source_location) != 2 or any(
        not split_source_location_elem
        for split_source_location_elem in split_source_location
    ):
        logging.info(
            "Source location `%s` doesn't have two `:` separated fields, ignoring it.",
            source_location,
        )
        return None
    line_number: int = int(split_source_location[1])
    if line_number <= 0:
        logging.info(
            "Source location `%s` has a non-positive line number %d, ignoring it.",
            source_location,
            line_number,
        )
        return None
    source_file: str = split_source_location[0]
    return SourceLocation(source_file, line_number)


def get_sum_all(sum_all: int) -> Optional[int]:
    if sum_all <= 0:
        logging.info("'Sum all' %d is non-positive, ignoring it.", sum_all)
        return None
    return sum_all


def get_code_line(code_line_list: list[Any]) -> Optional[CodeLine]:
    instruction: Optional[str] = get_instruction(str(code_line_list[0]))
    source_location: Optional[SourceLocation] = get_source_location(
        str(code_line_list[3])
    )
    sum_all: Optional[int] = get_sum_all(int(code_line_list[7]))
    if instruction is None or source_location is None or sum_all is None:
        logging.info("A code line field is empty or invalid, ignoring it.")
        return None
    return CodeLine(instruction, source_location, sum_all)


def read_code_lines(code_file_name: str) -> list[CodeLine]:
    try:
        with open(code_file_name, encoding="utf-8") as code_stream:
            code: list[list[Any]] = json.load(code_stream)["code"]
    except (FileNotFoundError, json.JSONDecodeError, KeyError):
        logging.exception("Error reading `%s` code file.", code_file_name)
        return []

    code_lines: list[CodeLine] = []
    for code_line_list in code:
        try:
            code_line: Optional[CodeLine] = get_code_line(code_line_list)
            if not code_line:
                continue
            code_lines.append(code_line)
        except (IndexError, ValueError):
            logging.exception(
                "Unexpected error while processing code line, please check string to integer"
                + " conversion or code line property positioning."
            )
            continue
    return code_lines


def get_line_number_filter(
    line_number_filter_str: str,
) -> Optional[int | tuple[int, int]]:
    try:
        if "-" not in line_number_filter_str:
            return int(line_number_filter_str)
        start_line_number: int
        end_line_number: int
        start_line_number, end_line_number = [
            int(line_number_str)
            for line_number_str in line_number_filter_str.split("-")
        ]
        if start_line_number > end_line_number:
            logging.warning(
                "Filter string is invalid because start line number %d"
                + " is greater than end line number %d.",
                start_line_number,
                end_line_number,
            )
            return None
        if start_line_number == end_line_number:
            return start_line_number
        return start_line_number, end_line_number
    except ValueError:
        logging.exception(
            "Unexpected error while processing filter string line numbers,"
            + " please check string to integer conversion."
        )
        return None


def get_filter(filter_str: str) -> Optional[SourceLocationFilter]:
    if not filter_str:
        logging.warning("Empty filter string, ignoring it.")
        return None
    filter_str = filter_str.strip()
    if not re.search(r"^[^\:]+\:(([0-9]+)|([0-9]+-[0-9]+))$", filter_str):
        logging.warning(
            "Filter string `%s` doesn't follow `%s` format, ignoring it.",
            filter_str,
            FILTER_STR_FORMAT,
        )
        return None
    source_file_filter: str
    line_number_filter_str: str
    source_file_filter, line_number_filter_str = filter_str.split(":")
    line_number_filter: Optional[int | tuple[int, int]] = get_line_number_filter(
        line_number_filter_str
    )
    if not line_number_filter:
        logging.warning(
            "Filter string `%s` has line number issues, ignoring it.", filter_str
        )
        return None
    return SourceLocationFilter(source_file_filter, line_number_filter)


def get_filters(filters_str: list[str]) -> list[SourceLocationFilter]:
    sloc_filters: list[SourceLocationFilter] = [
        sloc_filter
        for sloc_filter in (
            get_filter(filter_str) for filter_str in filters_str if filter_str
        )
        if sloc_filter
    ]
    if not sloc_filters:
        logging.warning("There's no valid filter, everything will be dumped.")
    return sloc_filters


def match_filter(code_line: CodeLine, sloc_filter: SourceLocationFilter) -> bool:
    if not code_line.source_location.source_file.endswith(
        sloc_filter.source_file_filter
    ):
        return False
    code_line_number: int = code_line.source_location.line_number
    line_number_filter: int | tuple[int, int] = sloc_filter.line_number_filter
    if isinstance(line_number_filter, int):
        return code_line_number == line_number_filter
    start_line_number: int
    end_line_number: int
    start_line_number, end_line_number = line_number_filter
    return start_line_number <= code_line_number <= end_line_number


def match_any_filter(
    code_line: CodeLine, sloc_filters: list[SourceLocationFilter]
) -> bool:
    for sloc_filter in sloc_filters:
        if match_filter(code_line, sloc_filter):
            return True
    return False


def filter_code_lines(
    code_lines: list[CodeLine], sloc_filters: list[SourceLocationFilter]
) -> list[CodeLine]:
    if not code_lines:
        return []
    if not sloc_filters:
        return code_lines
    return [
        code_line
        for code_line in code_lines
        if match_any_filter(code_line, sloc_filters)
    ]


def parse_args() -> tuple[str, list[SourceLocationFilter], str]:
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="filter ATT Viewer `code.json` data file"
    )
    parser.add_argument(
        "-c",
        "--code",
        required=True,
        help="input ATT Viewer `code.json` data file",
    )
    parser.add_argument(
        "-f",
        "--filter",
        nargs="*",
        help=f"filter string, follows `{FILTER_STR_FORMAT}` format",
    )
    default_output_file_name: str = "output.csv"
    parser.add_argument(
        "-o",
        "--output",
        default=default_output_file_name,
        help=f"output CSV file with filtered code, defaults to `{default_output_file_name}`",
    )
    args: argparse.Namespace = parser.parse_args()
    code_file_name: str = args.code
    sloc_filters: list[SourceLocationFilter] = (
        get_filters(args.filter) if args.filter else []
    )
    output_file_name: str = args.output
    return code_file_name, sloc_filters, output_file_name


def write_code_lines_as_csv(output_file_name: str, code_lines: list[CodeLine]) -> None:
    try:
        with open(output_file_name, mode="w", encoding="utf-8") as output_stream:
            output_writer = csv.writer(output_stream, quoting=csv.QUOTE_NONNUMERIC)
            output_writer.writerow(
                ["instruction", "source_file", "line_number", "sum_all"]
            )
            for code_line in code_lines:
                output_writer.writerow(
                    [
                        code_line.instruction,
                        code_line.source_location.source_file,
                        code_line.source_location.line_number,
                        code_line.sum_all,
                    ]
                )
    except Exception:  # pylint: disable=broad-exception-caught
        logging.exception("Error writing `%s` output file.", output_file_name)


def main() -> None:
    logging.basicConfig(format="%(asctime)s: %(message)s", level=logging.INFO)

    code_file_name: str
    sloc_filters: list[SourceLocationFilter]
    output_file_name: str
    code_file_name, sloc_filters, output_file_name = parse_args()

    code_lines: list[CodeLine] = read_code_lines(code_file_name)
    if not code_lines:
        logging.warning("There's no code lines to filter.")
        return
    logging.info("There's %d code lines to filter.", len(code_lines))

    filtered_code_lines: list[CodeLine] = filter_code_lines(code_lines, sloc_filters)
    if not filtered_code_lines:
        logging.warning("There's no filtered code lines.")
        return
    logging.info("There's %d code lines after filtering.", len(filtered_code_lines))

    write_code_lines_as_csv(output_file_name, filtered_code_lines)


if __name__ == "__main__":
    main()
