#!/usr/bin/env python

import sys

sys.path.append("/bin")
import os
import argparse
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.neighbors import LocalOutlierFactor
from scipy.stats import mannwhitneyu, ttest_ind, shapiro, false_discovery_control


def load_data(data_location, results_location, data_file):
    """Load metabolite data.

    Parameters:
    - data_location (str): Location of data files.
    - results_location (str): Location to store results.
    - data_file (str): Name of the data file.

    Returns:
    - pd.DataFrame: Loaded metabolite data.

    """
    file_path = data_file
    df_features_proc = pd.read_parquet(path=file_path)

    return df_features_proc


def test_normality(data, threshold):
    """Perform Shapiro-Wilk test for normality.

    Parameters:
    - data (pd.Series or pd.DataFrame): Data to test normality.

    Returns:
    - bool: Whether the data is normally distributed according to given threshold.
    - float: p-value of the Shapiro-Wilk test.

    """
    _, p_value = shapiro(data)
    return p_value > threshold


def main(args):
    """Main function to analyze metabolite data.

    Parameters:
    - args (argparse.Namespace): Command-line arguments.

    """
    df_features_proc = load_data(
        args.data_location, args.results_location, args.data_file
    )

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(df_features_proc)
    lof_outlier = LocalOutlierFactor()
    outlier_scores = lof_outlier.fit_predict(X_scaled)
    outlier_indices = outlier_scores == -1

    with open(os.path.join(args.results_location, "outliers.txt"), "w") as f:
        print(
            "Outliers detected:",
            df_features_proc[outlier_indices]
            .index.get_level_values(args.patient_metacol)
            .values,
            file=f,
        )

    disease_states = df_features_proc.index.get_level_values(
        args.disease_metacol
    ).unique()
    if len(disease_states) > 2:
        raise ValueError(
            "There are more than two unique disease states. Please specify which two to compare."
        )
    else:
        group1_data = df_features_proc[
            df_features_proc.index.get_level_values(args.disease_metacol).isin(
                [disease_states[0]]
            )
        ]
        group2_data = df_features_proc[
            df_features_proc.index.get_level_values(args.disease_metacol).isin(
                [disease_states[1]]
            )
        ]

    results = []

    for feature in df_features_proc.columns:
        is_normal_group1 = test_normality(group1_data[feature], args.pvalue_shapiro)
        is_normal_group2 = test_normality(group2_data[feature], args.pvalue_shapiro)

        if is_normal_group1 and is_normal_group2:
            stat, p = ttest_ind(group1_data[feature], group2_data[feature])
            results.append([feature, "T-test", stat, p])
        else:
            stat, p = mannwhitneyu(group1_data[feature], group2_data[feature])
            results.append([feature, "Mann-Whitney U", stat, p])

    df_results = pd.DataFrame(
        results, columns=["Feature", "Test", "Statistic", "p-value"]
    ).sort_values(by=["p-value"], ascending=True)

    df_results["FDR"] = false_discovery_control(df_results["p-value"])

    df_results.to_csv(
        os.path.join(args.results_location, "tables", f"univariate_analysis.csv"),
        header=True,
        sep=",",
        index=False,
        encoding="utf-8",
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Analyze metabolite data.")
    parser.add_argument("--data_location", default="", help="Location of data files.")
    parser.add_argument(
        "--results_location", default="results", help="Location to store results."
    )
    parser.add_argument(
        "--data_file", required=True, help="Name of the input data file."
    )
    parser.add_argument(
        "--disease_metacol", required=True, help="Name of the disease metadata column."
    )
    parser.add_argument(
        "--patient_metacol", required=True, help="Name of the patient metadata column."
    )
    parser.add_argument(
        "--pvalue_shapiro",
        default=0.05,
        help="Threshold for normality Shapiro-Wilk test.",
    )

    args = parser.parse_args()
    main(args)
