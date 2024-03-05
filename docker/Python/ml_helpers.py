#!/usr/bin/env python

import os
import matplotlib.pyplot as plt
import plotly.express as px
import seaborn as sns
import numpy as np
import pandas as pd
import shap


class MLException(Exception):
    """Exception linked to ML model relevance."""

    pass


def create_results_dir(results_location):
    """Create subdirectories 'tables' and 'figures' in the specified results location.

    Parameters:
    - results_location (str): Path to the directory where the subdirectories will be created.

    """
    subfolder_names = ["tables", "figures"]
    for subfolder in subfolder_names:
        os.makedirs(os.path.join(results_location, subfolder), exist_ok=True)


def data_loading(df, y_metacol):
    """Prepare data for machine learning by encoding the target variable.

    Parameters:
    - df (pd.DataFrame): Input DataFrame.
    - y_metacol (str): Name of the target variable column.

    Returns:
    - tuple: Tuple containing X (features) and y (target variable).

    """
    disease_states = df.index.get_level_values(y_metacol).unique()
    if len(disease_states) > 2:
        raise ValueError(
            "There are more than two unique disease states. Please specify which two to compare."
        )
    else:
        X = df
        y = (
            df.index.get_level_values(y_metacol)
            .to_series()
            .replace({disease_states[0]: 0, disease_states[1]: 1})
        )
    return (X, y)


def feature_subset(df, max_features=1000):
    """Select a subset of features from the DataFrame.

    Parameters:
    - df (pd.DataFrame): Input DataFrame.
    - max_features (int): Maximum number of features to select.

    Returns:
    - pd.DataFrame: DataFrame containing the selected features.

    """
    if df.shape[1] <= max_features:
        return df
    else:
        return df.sample(max_features, random_state=0, axis=1)


def ROC_AUC(model, X_test, y_test):
    """Print the ROC AUC score for a given model.

    Parameters:
    - model: Trained machine learning model.
    - X_test: Test set features.
    - y_test: Test set target variable.

    """
    y_probs = model.predict_proba(X_test)[:, 1]
    false_positive_rate, true_positive_rate, thresholds = roc_curve(y_test, y_probs)
    print(f"ROC AUC: {auc(false_positive_rate, true_positive_rate):.2f}")


def metadata_check(
    df, disease_metacol, minimum_class_threshold=3, minimum_class_perc_threshold=0.03
):
    """Check the metadata for class balance and feature availability.

    Parameters:
    - df (pd.DataFrame): Input DataFrame.
    - disease_metacol (str): Name of the disease metadata column.
    - minimum_class_threshold (int): Minimum count for each class.
    - minimum_class_perc_threshold (float): Minimum percentage for each class.

    """
    disease_states = df.index.get_level_values(disease_metacol).unique()
    if len(disease_states) != 2:
        raise ValueError(
            "There are more/less than two unique states. Please specify column with exact two states to compare."
        )
    else:
        disease_state_counts = df.index.get_level_values(disease_metacol).value_counts()
        n_patients = df.shape[0]
        disease_state1_count = disease_state_counts.get(disease_states[0], 0)
        disease_state2_count = disease_state_counts.get(disease_states[1], 0)
        if (disease_state1_count < minimum_class_threshold) or (
            (disease_state1_count / n_patients) < minimum_class_perc_threshold
        ):
            raise MLException(f"not enough {disease_states[0]} samples")
        if (disease_state2_count < minimum_class_threshold) or (
            (disease_state2_count / n_patients) < minimum_class_perc_threshold
        ):
            raise MLException(f"not enough {disease_states[1]} samples")
        if df.shape[1] < 5:
            raise MLException("not enough features")
    print(
        disease_states[0],
        ":",
        disease_state1_count,
        disease_states[1],
        ":",
        disease_state2_count,
    )


def create_pca_explained_variance_plot(
    explained_variance_ratio, results_location, pc_range=10, figsize=(12, 5)
):
    """Create and save a bar plot showing the explained variance in PCA.

    Parameters:
    - explained_variance_ratio (pd.Series): Explained variance ratio for each principal component.
    - results_location (str): Path to the directory where the plot will be saved.
    - figsize (tuple): Size of the plot.

    """
    fig = plt.figure(figsize=figsize)
    plt.bar(
        range(1, len(explained_variance_ratio[:pc_range]) + 1),
        explained_variance_ratio[:pc_range],
        alpha=0.5,
        align="center",
        label="Individual explained variance",
    )
    plt.step(
        range(1, len(explained_variance_ratio[:pc_range]) + 1),
        explained_variance_ratio[:pc_range].cumsum(),
        where="mid",
        label="Cumulative explained variance",
    )
    plt.ylabel("Explained variance ratio")
    plt.xlabel("Principal components")
    plt.legend(loc="best")
    plt.tight_layout()
    plt.xticks(range(1, len(explained_variance_ratio[:pc_range]) + 1))
    fig.savefig(
        os.path.join(results_location, "figures", f"pca_explained_variance_barplot.svg")
    )


def create_pca_matrix_plot(
    explained_variance_ratio, pca_result, df, metacol, results_location
):
    """Create and save a scatter matrix plot for PCA results.

    Parameters:
    - explained_variance_ratio (pd.Series): Explained variance ratio for each principal component.
    - pca_result (pd.DataFrame): PCA results.
    - df (pd.DataFrame): Input DataFrame.
    - metacol (str): Name of the metadata column.
    - results_location (str): Path to the directory where the plot will be saved.

    """
    labels = {
        str(i): f"PC {i+1} ({var:.1f}%)"
        for i, var in enumerate(explained_variance_ratio * 100)
    }
    fig = px.scatter_matrix(
        pca_result,
        labels=labels,
        dimensions=range(4),
        color=df.index.get_level_values(metacol),
        template="none",
        color_discrete_sequence=px.colors.qualitative.G10,
    )
    fig.update_traces(diagonal_visible=False, showupperhalf=False)
    fig.update_layout(width=1500, height=1000)
    fig.write_image(
        os.path.join(results_location, "figures", f"pca_matrix_{metacol}.svg")
    )


def create_distribution_plots(
    df, index_columns, metacol, results_location, n_size=10, figsize=(12, 8)
):
    """Create and save boxplots and distribution plots for random features.

    Parameters:
    - df (pd.DataFrame): Input DataFrame.
    - index_columns (list): List of index columns.
    - metacol (str): Name of the metadata column.
    - results_location (str): Path to the directory where the plots will be saved.
    - n_size (int): Number of features to plot.
    - figsize (tuple): Size of the plots.

    """
    features_col = df.sample(frac=1, random_state=1).columns
    random_features = np.random.RandomState(0).choice(
        features_col, size=min(n_size, features_col.size), replace=False
    )
    melted_df = df.reset_index().melt(
        id_vars=index_columns, var_name="Feature", value_vars=random_features
    )
    fig = plt.figure(figsize=figsize)
    box = sns.boxplot(
        data=melted_df,
        x="Feature",
        y="value",
        hue=metacol,
        palette="colorblind",
        native_scale=True,
    )
    plt.xticks(rotation=45)
    sns.move_legend(box, "upper left", bbox_to_anchor=(1, 1))
    plt.savefig(
        os.path.join(
            results_location, "figures", f"distribution_boxplots_{metacol}.svg"
        ),
        bbox_inches="tight",
    )
    fig = plt.figure(figsize=figsize)
    dist = sns.displot(
        melted_df,
        x="value",
        col="Feature",
        col_wrap=5,
        hue=metacol,
        height=4,
        aspect=1,
        kind="kde",
        palette="colorblind",
    )
    plt.savefig(
        os.path.join(
            results_location, "figures", f"distribution_distplots_{metacol}.svg"
        )
    )


def create_clustermaps(df, patient_metacol, results_location, figsize=(12, 6)):
    """Create and save clustermaps for feature and patient correlations.

    Parameters:
    - df (pd.DataFrame): Input DataFrame.
    - patient_metacol (str): Name of the patient metadata column.
    - results_location (str): Path to the directory where the plots will be saved.
    - figsize (tuple): Size of the plots.

    """
    df_features = (
        df.reset_index()
        .set_index([patient_metacol])
        .select_dtypes(include=["int64", "float64"])
    )
    df_patients = df_features.T
    fig = plt.figure(figsize=figsize)
    sns.clustermap(
        feature_subset(df_features, max_features=1000).corr().fillna(0),
        vmin=-1,
        vmax=1,
        center=0,
    )
    plt.savefig(
        os.path.join(
            results_location, "figures", f"correlation_clustermap_features.svg"
        )
    )
    fig = plt.figure(figsize=figsize)
    sns.clustermap(df_patients.corr(), vmin=-1, vmax=1, center=0)
    plt.savefig(
        os.path.join(
            results_location, "figures", f"correlation_clustermap_patients.svg"
        )
    )


def get_shap_values(X, y, cv, model, model_type="linear"):
    """Get SHAP values for a given model using cross-validation.

    Parameters:
    - X (pd.DataFrame): Input features.
    - y (pd.Series): Target variable.
    - cv: Cross-validation strategy.
    - model: Machine learning model.
    - model_type (str): Type of the model (linear or rf).

    Returns:
    - pd.DataFrame: DataFrame containing SHAP values.

    """
    shaps = {}
    for fold, (train_index, test_index) in enumerate(cv.split(X, y)):
        X_train, X_test, y_train, y_test = (
            X.iloc[train_index],
            X.iloc[test_index],
            y.iloc[train_index],
            y.iloc[test_index],
        )
        model.fit(X_train, y_train)
        masker = shap.maskers.Independent(data=X_test)
        if model_type == "linear":
            explainer = shap.LinearExplainer(model, masker=masker, random_seed=0)
            shap_values = explainer.shap_values(X_test)
        if model_type == "rf":
            explainer = shap.TreeExplainer(model, random_seed=0)
            shap_values = explainer.shap_values(X_test)[1]
        shaps[fold] = pd.DataFrame(
            shap_values, columns=X_test.columns, index=X_test.index
        )
    return pd.concat(shaps, names=["Fold"])


def get_shaps_relative_importance(shap_df, threshold=0.95):
    """Calculate relative importance of features based on SHAP values.

    Parameters:
    - shap_df (pd.DataFrame): DataFrame containing SHAP values.
    - threshold (float): Threshold for cumulative relative importance.

    Returns:
    - pd.DataFrame: DataFrame containing feature names and relative importance.

    """
    importance = shap_df.abs().mean()
    relative_importance = (importance / importance.sum()).sort_values(ascending=False)
    return pd.DataFrame(
        relative_importance.pipe(
            lambda imp: imp[imp.cumsum() < threshold]
        ).reset_index()
    ).set_axis(["Feature", "relative_importance"], axis=1)
