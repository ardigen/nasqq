#!/usr/bin/env python

import sys

sys.path.append("/bin")
import os
import argparse
import re
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.base import clone
from sklearn.datasets import make_classification
from sklearn.ensemble import ExtraTreesClassifier
from sklearn.linear_model import LogisticRegression, LogisticRegressionCV
from sklearn.model_selection import StratifiedShuffleSplit, cross_validate
from sklearn.preprocessing import StandardScaler
import shap
from ml_helpers import (
    data_loading,
    get_shap_values,
    get_shaps_relative_importance,
)


def load_data(
    data_location,
    results_location,
    disease_metacol,
    batch_metacol,
    patient_metacol,
    data_file,
):
    """Load and preprocess metabolite data.

    Parameters:
    - data_location (str): Location of data files.
    - results_location (str): Location to store results.
    - disease_metacol (str): Name of the disease metadata column.
    - batch_metacol (str): Name of the batch metadata column.
    - patient_metacol (str): Name of the patient metadata column.
    - data_file (str): Name of the data file.

    Returns:
    - X (pd.DataFrame): Features.
    - y (pd.Series): Target variable.

    """
    index_columns = [
        metacol
        for metacol in [batch_metacol, patient_metacol, disease_metacol]
        if metacol is not None
    ]
    file_path = os.path.join(data_file)
    df_features_proc = pd.read_parquet(path=file_path)
    X, y = data_loading(
        df_features_proc.sample(frac=1, random_state=1), disease_metacol
    )
    return X, y


def main(args):
    subdirectories = ["tables", "figures"]
    for directory in subdirectories:
        os.makedirs(os.path.join(args.results_location, directory), exist_ok=True)

    X, y = load_data(
        args.data_location,
        args.results_location,
        args.disease_metacol,
        args.batch_metacol,
        args.patient_metacol,
        args.data_file,
    )

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    models = {
        "Logistic regression (C=0)": LogisticRegression(random_state=0, C=0.1),
        "Logistic regression (C=1)": LogisticRegression(random_state=0, C=1.0),
        "Logistic regression L1 (C=0)": LogisticRegression(
            random_state=0, penalty="l1", tol=0.01, solver="saga", C=0.1
        ),
        "Logistic regression L1 (C=1)": LogisticRegression(
            random_state=0, penalty="l1", tol=0.01, solver="saga", C=1.0
        ),
        "Logistic regression L2 (C=0)": LogisticRegression(
            random_state=0, penalty="l2", tol=0.01, solver="saga", C=0.1
        ),
        "Logistic regression L2 (C=1)": LogisticRegression(
            random_state=0, penalty="l2", tol=0.01, solver="saga", C=1.0
        ),
        f"Logistic regression (CV={args.cross_val_fold})": LogisticRegressionCV(
            random_state=0,
            penalty="elasticnet",
            solver="saga",
            cv=args.cross_val_fold,
            l1_ratios=np.arange(0.1, 1, 0.1),
            max_iter=10000,
        ),
        "Random forest": ExtraTreesClassifier(random_state=0),
    }
    cv = StratifiedShuffleSplit(n_splits=200, random_state=0, test_size=args.test_size)

    results = {}
    for name, model in models.items():
        results[name] = pd.DataFrame(
            cross_validate(model, X_scaled, y, cv=cv, return_estimator=True, n_jobs=4)
        )
    results = pd.concat(results, names=["model"])
    results.to_csv(
        os.path.join(args.results_location, "tables", f"models_stratification.csv"),
        header=True,
        sep=",",
        index=True,
        encoding="utf-8",
    )

    best_model = results.groupby("model")["test_score"].mean().idxmax()
    shap_model = clone(models[best_model])

    cleaned_model_name = re.sub(r"\W+", "_", best_model.lower())
    if "Logistic regression" in best_model:
        plt.figure(figsize=(20, 25), dpi=400)
        weights = (
            results.loc[best_model]
            .apply(
                lambda row: pd.Series(row["estimator"].coef_[0], index=X.columns),
                axis=1,
            )
            .rename_axis("Split", axis=0)
            .rename_axis("Feature", axis=1)
            .stack()
            .rename("Weight")
            .reset_index()
        )
        sns.barplot(weights, x="Weight", y="Feature", errorbar="sd")
        plt.savefig(
            os.path.join(
                args.results_location, "figures", f"logistic_regression_weights.svg"
            )
        )

        prob_df = pd.concat(
            [
                weights.groupby("Feature")["Weight"].apply(lambda df: (df > 0).mean()), 
                weights.groupby("Feature")["Weight"].apply(lambda df: (df < 0).mean())
            ],
            axis=1
        )

        prob_df.columns = ['Positive Weights Proportion', 'Negative Weights Proportion']

        prob_df.sort_values(by='Positive Weights Proportion', ascending=False).to_csv(
            os.path.join(
                args.results_location,
                "tables",
                f"multivariate_analysis_{cleaned_model_name}_features_weights.csv",
            ),
            header=True,
            sep=",",
            index=True,
            encoding="utf-8",
        )
        shap_df = get_shap_values(X=X, y=y, cv=cv, model=shap_model)
    else:
        shap_df = get_shap_values(X=X, y=y, cv=cv, model=shap_model, model_type="rf")

    shap_relative_importance = get_shaps_relative_importance(shap_df=shap_df, threshold=0.95)
    shap_relative_importance.to_csv(
        os.path.join(
            args.results_location,
            "tables",
            f"multivariate_analysis_{cleaned_model_name}_features_relative_importance.csv",
        ),
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
        "--test_size", type=float, default=0.3, help="Test size for splitting data."
    )
    parser.add_argument(
        "--cross_val_fold",
        type=int,
        default=2,
        help="Number of cross-validation folds.",
    )

    args = parser.parse_args()
    main(args)
