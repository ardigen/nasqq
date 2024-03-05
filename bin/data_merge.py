#!/usr/bin/env python
import argparse
import pandas as pd
import numpy as np


def merge_files(txt_file, csv_file, output_file, batch_value, log1p, metadata_column):
    """Merge data from a text file and a CSV file based on specified columns.

    Parameters:
    - txt_file (str): Path to the text file containing data.
    - csv_file (str): Path to the CSV file containing data.
    - output_file (str): Path to the output file for the merged data.
    - batch_value (str): Value to be added in the 'batch' column of the text file.
    - log1p (bool): If True, apply log(1 + x) transformation to numeric columns.
    - metadata_column (str): Name of the column to be placed third in the merged DataFrame.

    Returns:
    - pd.DataFrame: Merged DataFrame.

    """
    df_txt = pd.read_csv(txt_file, sep=",", dtype={"patient_no": str})
    df_csv = pd.read_csv(csv_file, dtype={"patient_no": str})

    df_txt["batch"] = str(batch_value)

    columns_to_convert = ["patient_no", "batch"]
    for col in columns_to_convert:
        df_txt[col] = df_txt[col].astype(str).str.strip()
        df_csv[col] = df_csv[col].astype(str).str.strip()

    merged_df = pd.merge(df_txt, df_csv, on=["patient_no", "batch"])
    cols = ["patient_no", "batch", metadata_column] + [
        col
        for col in merged_df.columns
        if col not in ["patient_no", "batch", metadata_column]
    ]
    merged_df = merged_df[cols]

    if log1p:
        numeric_cols = merged_df.select_dtypes(include=[np.number]).columns
        merged_df[numeric_cols] = np.log1p(merged_df[numeric_cols])

    output_file_final = (
        output_file
        if batch_value != "None"
        else output_file.replace(".txt", "_without_merge.txt")
    )
    merged_df.to_csv(output_file_final, sep=";", index=False)
    return merged_df


def main():
    parser = argparse.ArgumentParser(description="Merge text and CSV files.")
    parser.add_argument("txt_file", type=str, help="Path to the text file")
    parser.add_argument("csv_file", type=str, help="Path to the CSV file")
    parser.add_argument("output_file", type=str, help="Path to the output file")
    parser.add_argument(
        "batch_value", type=str, help="Batch value to add to each observation"
    )
    parser.add_argument(
        "log1p",
        type=str,
        choices=["true", "false"],
        help="Apply log1p transformation to numeric columns",
    )
    parser.add_argument("metadata_column", type=str, help="Name of the metadata column")

    args = parser.parse_args()
    log1p = args.log1p.lower() == "true" if args.log1p else False

    merged_dataframe = merge_files(
        args.txt_file,
        args.csv_file,
        args.output_file,
        args.batch_value,
        log1p,
        args.metadata_column,
    )


if __name__ == "__main__":
    main()
