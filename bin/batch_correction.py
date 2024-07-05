#!/usr/bin/env python

import argparse
import os
import pandas as pd
from inmoose.pycombat import pycombat_norm
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

    file_path = os.path.join(data_location, data_file)
    df_features_proc = pd.read_parquet(file_path)

    return df_features_proc, index_columns

def apply_combat_correction(data_file, batch_metacol, results_location, covariates=None):
    """
    Apply ComBat batch correction using InMoose to the given data.

    Parameters:
    - data_file (str): Path to the Parquet file containing the data with a MultiIndex.
    - batch_metacol (str): The name of the metadata column indicating batch information.
    - results_location (str): Path to the directory where the corrected data will be saved.
    - covariates (pd.Series, optional): Series containing covariates for adjustment. Default is None.

    Returns:
    - None
    """
    try:
        data, index_columns = load_data(
            args.data_location,
            args.results_location,
            args.disease_metacol,
            args.batch_metacol,
            args.patient_metacol,
            args.data_file,
        )

        if not isinstance(data.index, pd.MultiIndex):
            raise ValueError("The input data must have a MultiIndex with 'batch' as one of the levels.")

        batch = data.index.get_level_values(batch_metacol)

        if len(batch) != data.shape[0]:
            raise ValueError("Mismatch between the length of the data and the batch labels.")

        if covariates is not None:
            covariates = covariates.loc[data.index]
            if len(covariates) != len(data):
                raise ValueError("Mismatch between the length of the data and the covariates.")

        data_t = data.T

        corrected_data_t = pycombat_norm(
            data_t,
            batch=batch.values,
            covariates=covariates.values.reshape(-1, 1) if covariates is not None else None,
            ref_batch=None,
            use_empirical_bayes=True,
            mean_only=False,
            verbose=False
        )

        corrected_data = pd.DataFrame(corrected_data_t.T, index=data.index, columns=data.columns)
        os.makedirs(results_location, exist_ok=True)
        results_file = os.path.join(results_location, "batch_corrected_data.parquet")
        corrected_data.to_parquet(results_file)

    except Exception as e:
        print(f"An error occurred during batch correction: {e}")

def main(args):
    covariates = pd.Series(args.covariates) if args.covariates else None
    apply_combat_correction(args.data_file, args.batch_metacol, os.path.join(args.results_location, "tables"), covariates)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Apply ComBat batch correction to metabolomics data.")
    parser.add_argument("--data_location", type=str, default="", help="Location of data files.")
    parser.add_argument("--results_location", type=str, default="results", help="Location to store results.")
    parser.add_argument("--data_file", type=str, required=True, help="Name of the data file.")
    parser.add_argument("--disease_metacol", type=str, required=True, help="Name of the disease metadata column.")
    parser.add_argument("--batch_metacol", type=str, help="Name of the batch metadata column.")
    parser.add_argument("--patient_metacol", type=str, required=True, help="Name of the patient metadata column.")
    parser.add_argument("--covariates", nargs='+', type=float, help="List of covariates for adjustment.")
    
    args = parser.parse_args()

    main(args)