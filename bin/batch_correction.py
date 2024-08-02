#!/usr/bin/env python

import argparse
import os
import pandas as pd
from inmoose.pycombat import pycombat_norm
from ml_helpers import *

def load_data(data_location, data_file, index_columns):
    """
    Load metabolite data.

    Parameters:
    - data_location (str): Location of data files.
    - data_file (str): Name of the data file.
    - index_columns (list): List of columns to be used as index.
    
    Returns:
    - pd.DataFrame: Loaded metabolite data.
    """
    df_features = pd.read_csv(
        os.path.join(data_location, data_file), sep=";", index_col=index_columns
    )
    return df_features

def apply_combat_correction(data, batch_metacol, covariates=None):
    """
    Apply ComBat batch correction using InMoose to the given data.

    Parameters:
    - data (pd.DataFrame): DataFrame containing the data with a MultiIndex.
    - batch_metacol (str): The name of the metadata column indicating batch information.
    - covariates (pd.Series, optional): Series containing covariates for adjustment. Default is None.

    Returns:
    - None
    """
    try:
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
        # corrected_data.to_parquet("metabolites_processed.parquet", index=True)
        corrected_data.to_csv("metabolites_batch_corrected.txt", sep=";", index=True)
        print("Batch corrected data saved to metabolites_batch_corrected.txt")

    except Exception as e:
        print(f"An error occurred during batch correction: {e}")

def main(args):
    index_columns = [col for col in [args.batch_metacol, args.patient_metacol, args.disease_metacol] if col]
    data = load_data(args.data_location, args.data_file, index_columns)
    covariates = pd.Series(args.covariates) if args.covariates else None
    apply_combat_correction(data, args.batch_metacol, covariates)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Apply ComBat batch correction to metabolomics data.")
    parser.add_argument("--data_location", type=str, default="", help="Location of data files.")
    parser.add_argument("--data_file", type=str, required=True, help="Name of the data file.")
    parser.add_argument("--disease_metacol", type=str, help="Name of the disease metadata column.")
    parser.add_argument("--batch_metacol", type=str, help="Name of the batch metadata column.")
    parser.add_argument("--patient_metacol", type=str, required=True, help="Name of the patient metadata column.")
    parser.add_argument("--covariates", nargs='+', type=float, help="List of covariates for adjustment.")
    
    args = parser.parse_args()
    main(args)
