#!/usr/bin/env python

import argparse
import pandas as pd
import glob
import os


def merge_csv_files(folder_path, output_name):
    """Merge data from multiple CSV files in the current directory into a single CSV
    file.

    Parameters:
    - folder_path (str): Name of the folder with input TSV files containing the merged features and metadata.
    - output_name (str): Name of the output TXT file containing the merged data. If the file
                        extension is not provided, '.txt' will be appended.

    Returns:
    - pd.DataFrame: Merged DataFrame containing the combined data from CSV files.

    """
    search_pattern = os.path.join(folder_path, "*.txt")
    file_list = sorted(glob.glob(search_pattern, recursive=True))

    merged_data = pd.concat(
        [pd.read_csv(file, sep=";") for file in file_list],
        ignore_index=True,
        sort=False,
    )
    merged_data.fillna(0, inplace=True)
    merged_data.to_csv(output_name, index=False, sep=";")

    return merged_data


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Merge CSV files and save as TXT")
    parser.add_argument("--folder_path", help="Specify the folder path", required=True)
    parser.add_argument(
        "--output_name", help="Specify the output file name", required=True
    )
    args = parser.parse_args()

    output_name = args.output_name
    folder_path = args.folder_path
    if not output_name.endswith(".txt"):
        output_name += ".txt"
    merge_csv_files(folder_path, output_name)
