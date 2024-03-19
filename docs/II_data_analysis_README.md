# Metabolites Data Processing and Analysis

Collection of scripts designed for Machine Learning data analysis based on quantified metabolites from the 1D 1H NMR Preprocessing Stage.

## I - Metabolites Data Processing

`features_processing.py` script is responsible for loading and preprocessing metabolites data. It removes columns with zero or NaN values and conducts metadata checks.

### Overview

The script performs the following tasks:

1. Loads metabolites data from a CSV file.
2. Preprocesses the data by removing columns with all zeros, and columns with a high percentage of zero or NaN values.
3. Performs metadata checks on the processed data.
4. Saves the processed data in PARQUET format.

## II - Metabolites Exploratory Data Analysis

`exploratory_data_analysis.py` script analyzes metabolites data using Principal Component Analysis (PCA) and generates visualizations for exploratory data analysis.

### Overview

The script performs the following tasks:

1. Loads PARQUET preprocessed metabolites data.
2. Applies PCA to reduce dimensionality.
3. Creates visualizations for PCA analysis, distribution plots, and cluster maps.
4. Saves the results in the specified directory.

## III - Metabolites Univariate Analysis

`univariate_analysis.py` script analyzes metabolites data, detects outliers, and performs univariate statistical tests on the data.

### Overview

The script performs the following tasks:

1. Loads PARQUET preprocessed metabolites data.
2. Detects outliers using Local Outlier Factor (LOF).
3. Compares two disease states using Mann-Whitney U and Kruskal-Wallis tests.
4. Controls for false discovery rate (FDR) and saves the results.

## IV - Metabolites Multivariate Analysis

`multivariate_analysis.py` script analyzes metabolites data using various machine learning models and provides insights into feature importance.

### Overview

The script is designed to perform the following tasks:

1. Loads PARQUET preprocessed metabolites data.
2. Train multiple machine learning models on the data.
3. Evaluate model performance using cross-validation.
4. Generate plots and tables for feature importance.

## Usage

### Prerequisites

Install the required Python packages by running:

```bash
pip install -r requirements.txt
```
**Note**: Scripts should be run one by one in a particular order. However, there is a possibility to run any of them separately, so one has to be cautious while handling data input.

### Running scripts

Navigate to your working directory and execute the realpath of the script's location with proper parameters by running the following commands accordingly:

```bash
python features_processing.py --data_location <data> --results_location <results> --data_file <metabolites.csv> --disease_metacol <disease_state> --batch_metacol <batch> --patient_metacol <patient_no> --zeronan_threshold 0.7
```
The script generates a processed metabolites data table (`metabolites_processed.parquet`) and saves it in the specified `<results>/tables` directory.

```bash
python exploratory_data_analysis.py --data_location <data> --results_location <results> --data_file <metabolites_processed.parquet> --disease_metacol <disease_state> --batch_metacol <batch> --patient_metacol <patient_no>
```
The script generates visualizations and saves them in the specified `<results>` directory. The output includes PCA plots, distribution plots, and cluster maps.

```bash
python univariate_analysis.py --data_location <data> --results_location <results> --data_file <metabolites_processed.parquet> --disease_metacol <disease_state> --batch_metacol <batch> --patient_metacol <patient_no>
```
The script generates a table (`univariate_analysis.csv`) containing the results of the univariate analysis, including U-statistic, U p-value, H-statistic, H p-value, U FDR, and H FDR. The table is saved in the specified `<results>/tables` directory.

```bash
python multivariate_analysis.py --data_location <data> --results_location <results> --data_file <metabolites_processed.parquet> --disease_metacol <disease_state> --batch_metacol <batch> --patient_metacol <patient_no> --test_size 0.3 --cross_val_fold 3
```
The results of the analysis are saved in the `<results>` directory, the key output files are:

* `models_stratification.csv`: Model performance metrics.
* `logistic_regression_weights.svg`: Bar plot of logistic regression feature weights.
* `multivariate_analysis_logistic_regression_features_weights.csv`: Table of logistic regression feature weights.
* `multivariate_analysis_logistic_regression_features_relative_importance.csv`: Table of relative feature importance shapley value based.

#### Command-line Arguments:

* **--data_location**: Location of data files. (default: ../data).
* **--results_location**: Location to store results. (default: ../results).
* **--data_file**: Name of the data file.
* **--patient_metacol**: Name of the patient metadata column.
* **--disease_metacol**: Name of the disease metadata column.
* **--batch_metacol**: Name of the batch metadata column. (If batch is yet to be discovered, leave empty.)
* **--zeronan_threshold**: Threshold for zero or NaN values.(default: 0.7)
* **--test_size**: Test size for splitting data. (default: 0.3)
* **--cross_val_fold**: Number of cross-validation folds. (default: 3)

Apart from main workflow scripts, supplementary `ml_helpers.py` script contains a collection of utility functions that serve different purposes in the machine learning pipeline, including data processing, analysis, and visualization.

Additional Notes:
* Adjust paths and filenames in the command based on your project structure.
* Ensure required dependencies (numpy, pandas, etc.) are installed from requirements.txt.
* Make sure the `ml_helpers.py` is available in the same location as all utilized scripts, as it contains the crucial functions for analysis.
* (Ideally) Run all scripts in provided Python_utils docker container.
* The scripts will create a directory structure under the specified results_location and save the processed data.
* Exploratory analysis will be executed followed by (uni-/multi-)variate analysis. Tables are stored separately from figures in dedicated folders.

#### License

This project is licensed under the MIT License - see the [LICENSE.md](../LICENSE.md) file for details.
