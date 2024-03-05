#!/usr/bin/env python

import sys

sys.path.append("/bin")
import os
import argparse
import pandas as pd
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from ml_helpers import *


def load_data(
    data_location,
    results_location,
    disease_metacol,
    batch_metacol,
    patient_metacol,
    data_file,
):
    """Load metabolite data.

    Parameters:
    - data_location (str): Location of data files.
    - results_location (str): Location to store results.
    - disease_metacol (str): Name of the disease metadata column.
    - batch_metacol (str): Name of the batch metadata column.
    - patient_metacol (str): Name of the patient metadata column.
    - data_file (str): Name of the data file.

    Returns:
    - pd.DataFrame: Loaded metabolite data.
    - list: Index columns.

    """
    index_columns = [
        metacol
        for metacol in [batch_metacol, patient_metacol, disease_metacol]
        if metacol is not None
    ]

    file_path = os.path.join(data_file)
    df_features_proc = pd.read_parquet(path=file_path)

    return df_features_proc, index_columns


def main(args):
    """Main function to process and analyze metabolite data.

    Parameters:
    - args (argparse.Namespace): Command-line arguments.

    """
    create_results_dir(args.results_location)

    df_features_proc, index_columns = load_data(
        args.data_location,
        args.results_location,
        args.disease_metacol,
        args.batch_metacol,
        args.patient_metacol,
        args.data_file,
    )

    scaler = StandardScaler()
    scaled_data = scaler.fit_transform(df_features_proc)
    valid_n_components = min(scaled_data.shape[0], scaled_data.shape[1])
    pca = PCA(n_components=valid_n_components)
    pca_result = pca.fit_transform(scaled_data)
    explained_variance_ratio = pca.explained_variance_ratio_

    create_pca_explained_variance_plot(
        explained_variance_ratio=explained_variance_ratio,
        results_location=args.results_location,
    )

    create_pca_matrix_plot(
        explained_variance_ratio=explained_variance_ratio,
        pca_result=pca_result,
        df=df_features_proc,
        metacol=args.disease_metacol,
        results_location=args.results_location,
    )

    create_distribution_plots(
        df=df_features_proc,
        index_columns=index_columns,
        metacol=args.disease_metacol,
        results_location=args.results_location,
    )

    if args.batch_metacol is not None:
        create_pca_matrix_plot(
            explained_variance_ratio=explained_variance_ratio,
            pca_result=pca_result,
            df=df_features_proc,
            metacol=args.batch_metacol,
            results_location=args.results_location,
        )
        create_distribution_plots(
            df=df_features_proc,
            index_columns=index_columns,
            metacol=args.batch_metacol,
            results_location=args.results_location,
        )
        
        patient_batch_index = df_features_proc.index.get_level_values('patient_no').astype(str) + '_' + df_features_proc.index.get_level_values('batch').astype(str)
        create_clustermaps(
            df=df_features_proc.set_index(patient_batch_index),
            patient_metacol=patient_batch_index,
            results_location=args.results_location,
        )
    else:
        create_clustermaps(
            df=df_features_proc,
            patient_metacol=args.patient_metacol,
            results_location=args.results_location,
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

    args = parser.parse_args()
    main(args)
