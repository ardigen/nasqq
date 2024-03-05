#!/usr/bin/env python


import sys

sys.path.append("/bin")
import os

os.environ["MPLCONFIGDIR"] = ".config/matplotlib"
os.environ["FONTCONFIG_PATH"] = "fontconfig_cache"
import numpy as np
import pandas as pd
import argparse
from ml_helpers import create_results_dir, metadata_check


def load_and_process_data(data_location, data_file, index_columns, zeronan_threshold):
    """Load and preprocess metabolite data.

    Parameters:
    - data_location (str): Location of data files.
    - data_file (str): Name of the data file.
    - index_columns (list): List of columns to be used as index.
    - zeronan_threshold (float): Threshold for zero or NaN values.

    Returns:
    - pd.DataFrame: Processed metabolite data.

    """
    df_features = pd.read_csv(
        os.path.join(data_location, data_file), sep=";", index_col=index_columns
    )

    # Drop columns with all zeros
    columns_with_zeros = df_features.columns[df_features.eq(0).all()]
    df_features.drop(columns=columns_with_zeros, inplace=True)

    cols_to_remove = []

    for col in df_features.columns:
        # Skip non-numeric columns
        if not np.issubdtype(df_features[col].dtype, np.number):
            continue

        zero_percentage = (df_features[col] == 0).mean()
        nan_percentage = (df_features[col].isna()).mean()
        zeronan_percentage = (
            (df_features[col].isna()) | (df_features[col] == 0)
        ).mean()

        if (zero_percentage > zeronan_threshold) or (
            nan_percentage > zeronan_threshold
        ):
            cols_to_remove.append(col)
        elif zeronan_percentage > zeronan_threshold:
            cols_to_remove.append(col)

    df_features_proc = df_features.drop(columns=list(set(cols_to_remove)))
    return df_features_proc


def main(args):
    """Main function to process and analyze metabolite data.

    Parameters:
    - args (argparse.Namespace): Command-line arguments.

    """
    create_results_dir(args.results_location)

    index_columns = [
        metacol
        for metacol in [args.batch_metacol, args.patient_metacol, args.disease_metacol]
        if metacol is not None
    ]

    df_features_proc = load_and_process_data(
        args.data_location, args.data_file, index_columns, args.zeronan_threshold
    )

    metadata_check(df_features_proc, args.disease_metacol)

    df_features_proc.to_parquet(
        path=os.path.join(
            args.results_location, "tables", "metabolites_processed.parquet"
        ),
        index=True,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process and analyze metabolite data.")
    parser.add_argument("--data_location", default="", help="Location of data files.")
    parser.add_argument(
        "--results_location", default="results", help="Location to store results."
    )
    parser.add_argument("--data_file", required=True, help="Name of the data file.")
    parser.add_argument(
        "--disease_metacol", required=True, help="Name of the disease metadata column."
    )
    parser.add_argument(
        "--batch_metacol",
        help="Name of the batch metadata column. If batch is yet to be discovered, leave empty.",
    )
    parser.add_argument(
        "--patient_metacol", required=True, help="Name of the patient metadata column."
    )
    parser.add_argument(
        "--zeronan_threshold",
        type=float,
        default=0.7,
        help="Threshold for zero or NaN values. Must be a float.",
    )

    args = parser.parse_args()
    os.makedirs(args.results_location, exist_ok=True)

    main(args)
