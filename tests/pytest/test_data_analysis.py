#!/usr/bin/env python

from argparse import Namespace
import os
import pytest
import pandas as pd
import random
import sys

# Import modules from bin directory
sys.path.append("../../bin/")
from data_merge import merge_files
from merge_batches import merge_csv_files
from exploratory_data_analysis import main as main_eda
from features_processing import main as main_features_processing, load_and_process_data
from univariate_analysis import main as main_univariate
from multivariate_analysis import main as main_multivariate

# Set random seed for reproducibility
random.seed(1234)

# Function to generate sample data file path
def get_sample_data_path(file_number, file_type):
    data_location = os.getcwd()
    file_extension = "csv" if file_type == "metadata" else "txt"
    file_name = f"test_{file_type}_{file_number}.{file_extension}"
    return os.path.join(data_location, file_name)

# Fixture for sample metadata data file path
@pytest.fixture
def sample_metadata_data(request, file_number):
    return get_sample_data_path(file_number, "metadata")

# Fixture for sample features data file path
@pytest.fixture
def sample_features_data(request, file_number):
    return get_sample_data_path(file_number, "features")

# Fixture for output file path
@pytest.fixture
def output_file(tmpdir, file_number):
    return str(tmpdir.join(f'test_merged_features_metadata_{file_number}.txt'))

# Fixture for data location
@pytest.fixture
def data_location(request):
    return request.config.cache.get("result_df_directory", default=None)

# Fixture for data file
@pytest.fixture
def data_file(request):
    return request.config.cache.get("metabolites_processed_file", default=None)

# Test for merging files
@pytest.mark.parametrize("file_number", [1, 2, 3])
def test_merge_files(request, sample_metadata_data, sample_features_data, output_file, file_number):
    batch_value = f'batch{file_number}'
    log1p = False
    metadata_column = 'State'

    merged_df = merge_files(sample_metadata_data, sample_features_data, output_file, batch_value, log1p, metadata_column)
    
    assert isinstance(merged_df, pd.DataFrame)
    assert not merged_df.empty, f"The merged DataFrame for file {file_number} is empty"
    assert os.path.exists(output_file)
    assert os.path.getsize(output_file) > 0, f"The output file for file {file_number} is empty"
    assert all(col in merged_df.columns for col in ['patient_no', 'batch', metadata_column])

    request.config.cache.set(f"test_merged_features_metadata_{file_number}", output_file)

# Test for merging batches
def test_merge_batches(request, tmpdir, data_location):
    output_files = [
        request.config.cache.get(f"test_merged_features_metadata_{file_number}", default=None) 
        for file_number in [1, 2, 3]
    ]
    
    assert all(output_files), "Some output files are missing"

    result_file = str(tmpdir.join("test_merged_features_metadata.csv"))
    folder_path = os.path.join(os.path.commonpath(output_files), "**/test_merge_files_*_current/")

    merge_csv_files(folder_path, result_file)
    
    result_df = pd.read_csv(result_file, sep=';')
    assert not result_df.empty

    result_df_directory = os.path.dirname(result_file)
    request.config.cache.set("result_df_directory", result_df_directory)

# Test for loading and processing data
@pytest.mark.filterwarnings("ignore:np.find_common_type*")
def test_load_and_process_data(request, data_location, data_file):
    data_file = "test_merged_features_metadata.csv"
    index_columns = ['patient_no', 'batch', 'State']
    zeronan_threshold = 0.7

    processed_data = load_and_process_data(data_location, data_file, index_columns, zeronan_threshold)
    assert isinstance(processed_data, pd.DataFrame)
    assert all(col in processed_data.index.names for col in index_columns)

# Test for main features processing
@pytest.mark.filterwarnings("ignore:np.find_common_type*")
def test_main_features_processing(request, tmpdir, data_location):
    results_location = str(tmpdir.mkdir("results"))
    data_file = "test_merged_features_metadata.csv"
    disease_metacol = "State"
    batch_metacol = "batch"
    patient_metacol = "patient_no"
    zeronan_threshold = 0.7

    args_features_processing = Namespace(
        data_location=data_location,
        results_location=results_location,
        data_file=data_file,
        disease_metacol=disease_metacol,
        batch_metacol=batch_metacol,
        patient_metacol=patient_metacol,
        zeronan_threshold=zeronan_threshold
    )
    main_features_processing(args_features_processing)

    metabolites_processed_file = os.path.join(results_location, "tables", "metabolites_processed.parquet")
    assert os.path.exists(metabolites_processed_file)
    request.config.cache.set("metabolites_processed_file", metabolites_processed_file)

# Test for main exploratory data analysis
@pytest.mark.filterwarnings("ignore::DeprecationWarning")
def test_main_eda(request, tmpdir, data_location, data_file):
    results_location = str(tmpdir.mkdir("results"))
    disease_metacol = "State"
    patient_metacol = "patient_no"
    batch_metacol = "batch"

    args_eda = Namespace(
        data_location=data_location,
        results_location=results_location,
        data_file=data_file,
        disease_metacol=disease_metacol,
        patient_metacol=patient_metacol,
        batch_metacol=batch_metacol
    )

    os.makedirs(os.path.join(results_location, "figures"), exist_ok=True)
    main_eda(args_eda)

    figures_file_names = [
        "pca_explained_variance_barplot.svg",
        "pca_matrix_batch.svg",
        "pca_matrix_State.svg",
        "correlation_clustermap_features.svg",
        "correlation_clustermap_patients.svg",
        "distribution_boxplots_batch.svg",
        "distribution_boxplots_State.svg",
        "distribution_distplots_batch.svg",
        "distribution_distplots_State.svg"
    ]

    for file_name in figures_file_names:
        assert os.path.exists(os.path.join(results_location, "figures", file_name)) 

# Test for main univariate analysis
@pytest.mark.filterwarnings("ignore:n_neighbors*", "ignore:np.find_common_type*")
def test_main_univariate(request, tmpdir, data_location, data_file):
    results_location = str(tmpdir.mkdir("results"))
    disease_metacol = "State"
    patient_metacol = "patient_no"
    pvalue_shapiro = 0.05

    args_univariate = Namespace(
        data_location=data_location,
        results_location=results_location,
        data_file=data_file,
        disease_metacol=disease_metacol,
        patient_metacol=patient_metacol,
        pvalue_shapiro=pvalue_shapiro
    )

    os.makedirs(os.path.join(results_location, "tables"), exist_ok=True)
    main_univariate(args_univariate)

    assert os.path.exists(os.path.join(results_location, "tables", "univariate_analysis.csv"))

    outliers_file = os.path.join(results_location, "outliers.txt")
    assert os.path.exists(outliers_file), "outliers.txt file does not exist"

    results_file = os.path.join(results_location, "tables", "univariate_analysis.csv")
    results_df = pd.read_csv(results_file)

    assert not results_df.empty
    assert all(col in results_df.columns for col in ['Feature', 'Test', 'Statistic', 'p-value', 'FDR'])

# Test for main multivariate analysis
@pytest.mark.filterwarnings("ignore:DeprecationWarning")
def test_main_multivariate(request, tmpdir, data_location, data_file):
    results_location = str(tmpdir.mkdir("results"))
    disease_metacol = "State"
    patient_metacol = "patient_no"
    batch_metacol = "batch"

    args_multivariate = Namespace(
        data_location=data_location,
        results_location=results_location,
        data_file=data_file,
        disease_metacol=disease_metacol,
        patient_metacol=patient_metacol,
        batch_metacol=batch_metacol,
        test_size=0.5,
        cross_val_fold=2
    )

    os.makedirs(os.path.join(results_location, "tables"), exist_ok=True)
    os.makedirs(os.path.join(results_location, "figures"), exist_ok=True)
    main_multivariate(args_multivariate)

    models_file_names = ["models_stratification.csv",
                         "multivariate_analysis_logistic_regression_l1_c_1__features_relative_importance.csv",
                         "multivariate_analysis_logistic_regression_l1_c_1__features_weights.csv", 
    ]

    for file_name in models_file_names:
        assert os.path.exists(os.path.join(results_location, "tables", file_name))
    
    assert os.path.exists(os.path.join(results_location, "figures", "logistic_regression_weights.svg"))


    results_file_models_stratification = os.path.join(results_location, "tables", models_file_names[0])
    models_stratification_df = pd.read_csv(results_file_models_stratification)

    assert models_stratification_df.shape == (1600, 6)
    assert all(column in models_stratification_df.columns for column in ['model', 'fit_time', 'score_time', 'estimator', 'test_score'])

    results_file_relative_importance = os.path.join(results_location, "tables", models_file_names[1])
    relative_importance_df = pd.read_csv(results_file_relative_importance)

    assert not relative_importance_df.empty
    assert 'Feature' in relative_importance_df.columns
    assert 'relative_importance' in relative_importance_df.columns
