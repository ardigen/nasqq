# Metabolites Spectral Processing and Identification

Collection of scripts designed for spectral preprocessing of metabolites from the 1D 1H NMR Experiments.

## I - Raw FIDs Loading

`load_fids.R` script is responsible for loading raw FIDs data in Bruker format and selecting specific samples based on the pulse program and removing duplicated sample names.

```bash
./load_fids.R --id <ID> --raw_data_path <Raw Data Path> --pulse_program <Pulse Program> [--selected_sample_names <Selected Sample Names>] [--rm_duplicated_names]
```

### Options

* `--id`: ID for the data processing.
* `--raw_data_path`: Path to the raw NMR data.
* `--pulse_program`: Pulse program value for consistency filtering samples.
* `--selected_sample_names` (Optional): Specify a subset of sample names to include (default: `"all"`).
* `--rm_duplicated_names` (Optional): Remove duplicated sample names (default: `FALSE`).

### Output

Two RDS files are generated, both comprise FIDdata (matrix) and FIDinfo (metadata):

* `<ID>_original_fid_list.rds`: Original FID list before preprocessing.
* `<ID>_selected_fid_list.rds`: Selected FID list after preprocessing.

## II - Raw FIDs Visualisation

`raw_fids_visualisation.R` script is designed to generate and save raw FIDs plots.

```bash
./raw_fids_visualisation.R --id <ID> --raw_rds <Raw Data RDS>
```

### Options

* `--id`: ID for the data processing.
* `--raw_rds`: Path to the RDS file with `fid_list` object.

### Output

The script generates raw FID plots for each sample and saves them in the current working directory. Additionally, a serialized RDS file `<ID>_raw_plots_list.rds` containing the raw plots is created.

## III - Group Delay Correction

`group_delay_corection.R` The script performs group delay removal (GDC) on the input data and generates comparison plots (before/ after GDC).

```bash
./group_delay_corection.R --id <ID> --raw_rds <Raw Data RDS>
```

### Options

* `--id`: ID for the data processing.
* `--raw_rds`: Path to the RDS file with `fid_list` object.

### Output

The script generates the following outputs:

RDS Files:
* `<ID>_gdc_compared_plots.rds`: RDS file containing the list of compared plots.
* `<ID>_grouped_FIDdata_GDC.rds`: RDS file containing the grouped and GDC-corrected FIDdata.
Plots:
* Comparison plots before and after GDC, saved in SVG format with the suffix `"<Sample ID>_gdc_plot.svg"`.

## IV - Solvent Suppresion

`solvent_suppresion.R` script applies apodization and generates comparison plots before and after processing.

```bash
./solvent_suppression.R --id <ID> --raw_rds <Raw Data RDS> --fid_gdc <FID GDC Data RDS>
```

### Options

* `--id`: ID for the data processing.
* `--raw_rds`: Path to the RDS file with `fid_list` object.
* `--fid_gdc`: Path to the RDS file with FID data post-GDC.

### Output

The script generates the following outputs:

RDS Files:
* `<ID>_ss_compared_plots.rds`: RDS file containing the list of compared plots.
* `<ID>_grouped_FIDdata_GDC.rds`: RDS file containing the grouped and solvent-suppressed FIDdata.
Plots:
* Comparison plots before and after SS, saved in SVG format with the suffix `"<Sample ID>_ss_plot.svg"`.

## V - Apodization

`apodization.R` script analyzes metabolite data using various machine learning models and provides insights into feature importance.

```bash
./apodization.R --id <ID> --raw_rds <Raw Data RDS> --ss_res <FID SS Data RDS> [--pulse_prog_value <Pulse Program>]
```

### Options

* `--id`: ID for the data processing.
* `--raw_rds`: Path to the RDS file with `fid_list` object.
* `--ss_res`: Path to the RDS file with FID data post-SS.
* `--pulse_prog_value` (Optional): Pulse program value for expLB assignment.

### Output

The script generates the following outputs:

RDS Files:
* `<ID>_apodization_compared_plots.rds`: RDS file containing the list of compared plots.
* `<ID>_grouped_FIDdata_A.rds`: RDS file containing the grouped and apodized FIDdata.
Plots:
* Comparison plots before and after SS, saved in SVG format with the suffix `"<Sample ID>_a_plot.svg"`.

## VI - Zero Filling

`zero_filling.R` script performs zero-filling and provides visualization to compare FID data before and after the zero-filling process.

```bash
./zero_filling.R --id <ID> --raw_rds <Raw Data RDS> --fid_a <FID A Data RDS>
```

### Options

* `--id`: ID for the data processing.
* `--raw_rds`: Path to the RDS file with `fid_list` object.
* `--fid_a`: Path to the RDS file with FID data post-A.

### Output

The script generates the following outputs:

RDS Files:
* `<ID>_zerofilling_compared_plots.rds`: RDS file containing the list of compared plots.
* `<ID>_grouped_FIDdata_ZF.rds`: RDS file containing the grouped and zerofilled FIDdata.
Plots:
* Comparison plots before and after ZF, saved in SVG format with the suffix `"<Sample ID>_zf_plot.svg"`.

## VII - Fourier Transformation

`fourier_transformation.R` script performs the Fourier Transform on Free Induction Decay (FID) signals obtained after zero-filling.

```bash
./fourier_transformation.R --id <ID> --raw_rds <Raw Data RDS> --fid_zf <FID ZF Data RDS>
```

### Options

* `--id`: ID for the data processing.
* `--raw_rds`: Path to the RDS file with `fid_list` object.
* `--fid_zf`: Path to the RDS file with FID data post-ZF.

### Output

The script generates the following outputs:

RDS Files:
* `<ID>_ft_compared_plots.rds`: RDS file containing the list of compared plots.
* `<ID>_grouped_RawSpect_data_FT.rds`: RDS file containing the grouped and FT spectra.
Plots:
* Comparison plots before and after FT, saved in SVG format with the suffix `"<Sample ID>_ft_plot.svg"`.

## VIII - Zero Order Phase Correction

`zero_order_phase_correction.R` script is designed for performing Zero Order Phase Correction (ZOPC) on Fourier-transformed spectra.

```bash
./zero_order_phase_correction.R --id <ID> --raw_rds <Raw Data RDS> --raw_spect_ft <FT Spectra RDS>
```

### Options

* `--id`: ID for the data processing.
* `--raw_rds`: Path to the RDS file with `fid_list` object.
* `--raw_spect_ft`: Path to the RDS file with spectra data post-FT.

### Output

The script generates the following outputs:

RDS Files:
* `<ID>_zopc_plots.rds`: RDS file containing the list of compared plots.
* `<ID>_grouped_Spectrum_data_ZOPC.rds`: RDS file containing the grouped and ZOPC spectra.
Plots:
* Plots after ZOPC, saved in SVG format with the suffix `"<Sample ID>_zopc_plot.svg"`.

## IX - Internal Referencing

`internal_referencing.R` script performs internal referencing based on specified compound parameters.

```bash
./internal_referencing.R --id <ID> --raw_rds <Raw Data RDS> --spectra_zopc <FT Spectra RDS> [--target_value <Reference Target Value>] [--fromto_rc <PPM Range>] [--reverse_axis_samples <Reverse Axis Samples Value>]
```

### Options

* `--id`: ID for the data processing.
* `--raw_rds`: Path to the RDS file with `fid_list` object.
* `--spectra_zopc`: Path to the RDS file with spectra data post-ZOPC.
* `--target_value` (Optional): Target value for internal referencing (default: 0).
* `--fromto_rc` (Optional): PPM Range for internal referencing in the format "from;to".
* `--reverse_axis_samples` (Optional): Whether reverse axis for `all` or `selected` samples.

### Output

The script generates the following outputs:

RDS Files:
* `<ID>_ir_compared_plots.rds`: RDS file containing the list of compared plots.
* `<ID>_grouped_Spectrum_data_IR.rds`: RDS file containing the grouped and IR spectra.
Plots:
* Comparison plots before and after IR, saved in SVG format with the suffix `"<Sample ID>_ir_plot.svg"`.

## X - Baseline Correction

`baseline_correction.R` script performs baseline correction on given spectra.

```bash
./baseline_correction.R --id <ID> --raw_rds <Raw Data RDS> --spectra_ir <IR Spectra RDS> [--lambda_bc <Lambda Parameter>] [--p_bc <P Parameter>]
```

### Options

* `--id`: ID for the data processing.
* `--raw_rds`: Path to the RDS file with `fid_list` object.
* `--spectra_ir`: Path to the RDS file with spectra data post-IR.
* `--lambda_bc` (Optional): Lambda parameter for baseline correction (default: `5e+06`).
* `--p_bc` (Optional): P parameter for baseline correction (default: `0.0001`).

### Output

The script generates the following outputs:

RDS Files:
* `<ID>_bc_compared_plots.rds`: RDS file containing the list of compared plots.
* `<ID>_grouped_Spectrum_data_BC.rds`: RDS file containing the grouped and BC spectra.
Plots:
* Comparison plots before and after BC, saved in SVG format with the suffix `"<Sample ID>_bc_plot.svg"`.

## XI - Negative Values Zeroing

`negative_values_zeroing.R` script for post-baseline correction processing of the spectra, performs negative values zeroing.

```bash
./negative_values_zeroing.R --id <ID> --raw_rds <Raw Data RDS> --spectra_bc <BC Spectra RDS>
```

### Options

* `--id`: ID for the data processing.
* `--raw_rds`: Path to the RDS file with `fid_list` object.
* `--spectra_bc`: Path to the RDS file with spectra data post-BC.

### Output

The script generates the following outputs:

RDS Files:
* `<ID>_nvz_plots.rds`: RDS file containing the list of plots.
* `<ID>_grouped_Spectrum_data_NVZ.rds`: RDS file containing the grouped and NVZ spectra.
Plots:
* Plots after NVZ, saved in SVG format with the suffix `"<Sample ID>_nvz_plot.svg"`.

## XII - Warping

`warping.R` script performs warping to align the spectra.

```bash
./warping.R --id <ID> --raw_rds <Raw Data RDS> --spectra_nvz <NVZ Spectra RDS>
```

### Options

* `--id`: ID for the data processing.
* `--raw_rds`: Path to the RDS file with `fid_list` object.
* `--spectra_nvz`: Path to the RDS file with spectra data post-NVZ.

### Output

The script generates the following outputs:

RDS Files:
* `<ID>_w_compared_plots.rds`: RDS file containing the list of compared plots.
* `<ID>_grouped_Spectrum_data_W.rds`: RDS file containing the grouped and NVZ spectra.
Plots:
* Comparison plots before and after Warping, saved in SVG format with the suffix `"<Sample ID>_w_plot.svg"`.

## XIII - Window Selection

`window_selection.R` script performs selecting informative part of spectra.

```bash
./window_selection.R --id <ID> --spectra_nvz <NVZ Spectra RDS> [--from_ws <Lower Limit>] [--to_ws <Upper Limit>]
```

### Options

* `--id`: ID for the data processing.
* `--spectra_nvz`: Path to the RDS file with spectra data post-NVZ (or optionally post-W).
* `--from_ws` (Optional): Limit for the lower bound of the window in ppm (default: 10).
* `--to_ws` (Optional): Limit for the upper bound of the window in ppm (default: 0).

### Output

The script generates the `<ID>_grouped_Spectrum_data_WS.rds` RDS file containing the grouped and limited spectra.

## XIV - Bucketing

`bucketing.R` script performs bucketing for simplyfing spectra's resolution.

```bash
./bucketing.R --id <ID> --raw_rds <Raw Data RDS> --spectra_ws <WS Spectra RDS> [--intmeth <Method>] [--width <Width>] [--mb <MB>]
```

### Options

* `--id`: ID for the data processing.
* `--raw_rds`: Path to the RDS file with `fid_list` object.
* `--spectra_ws`: Path to the RDS file with spectra data post-WS.
* `--intmeth` (Optional): Type of bucketing, rectangular or trapezoidal - Options: `"r"`, `"t"` (default: `t`).
* `--mb` (Optional): Number or width of buckets, depending on width argument (default: 10000).
* `--width` (Optional):  Whether mb represents width or not (default: `FALSE`).

### Output

The script generates the following outputs:

RDS Files:
* `<ID>_b_compared_plots.rds`: RDS file containing the list of compared plots.
* `<ID>_grouped_Spectrum_data_B.rds`: RDS file containing the grouped and B spectra.
Plots:
* Comparison plots before and after Bucketing, saved in SVG format with the suffix `"<Sample ID>_b_plot.svg"`.

## XV - Normalization

`normalization.R` script performs spectra normalization.

```bash
./normalization.R --id <ID> --raw_rds <Raw Data RDS> --spectra_ws <WS Spectra RDS> [--type_norm <Normalization Type>] [--removal_regions <Removal Regions>]
```

### Options

* `--id`: ID for the data processing.
* `--raw_rds`: Path to the RDS file with `fid_list` object.
* `--spectra_ws`: Path to the RDS file with spectra data post-WS (or optionally post-B).
* `--type_norm` (Optional): Normalization type, one of: `"mean"`, `"pqn"`, `"median"`, `"firstquartile"`, `"peak"` (default: `pqn`).
* `--removal_regions` (Optional): Regions of spectra to be removed, by default Water and Noise around 0 ppms (default: `list(Water = c(4.5, 5.1), Noise = c(0.0, 0.1))`).

### Output

The script generates `normalized_metabolites.txt` TXT file with normalized ppms and the following outputs:

RDS Files:
* `<ID>_n_plots.rds`: RDS file containing the list of compared plots.
* `<ID>_grouped_Spectrum_data_N.rds`: RDS file containing the grouped and BC spectra.
Plots:
* Plots after Normalization, saved in SVG format with the suffix `"<Sample ID>_n_plot.svg"`.
* `Spectrum_data_WS_stacked.pdf` plot with stacked all spectra pre-normalization.
* `Spectrum_data_N_stacked.pdf` plot with stacked all spectra post-normalization.

## XVI - Metabolites Quantification

`asics_quantification.R` script performs metabolite quantification using the ASICS algorithm.

```bash
./asics_quantification.R --id <ID> --dir-path <Directory Path> --peps-format-file <PepsNMR File Path> --ncores <Number Of Cores> [--quantif-method <Quantification Method>] [--reference <Reference Spectrum>] [--normalisation] [--baseline-correction] [--alignment]
```

### Options

* `--id`: ID for the data processing.
* `--dir-path`: Directory path to the PepsNMR data.
* `--peps-format-file`: PepsNMR format file name.
* `--ncores`: Number of cores for computing.
* `--quantif-method` (Optional): Quantification method (default: `"both"`) - Options: `"FWER"`, `"Lasso"`, `"both"`.
* `--reference` (Optional): Reference spectrum for alignment (default: `NULL`).
* `--normalisation` (Optional): Perform spectra normalization (default: `FALSE`).
* `--baseline-correction` (Optional): Perform spectra baseline correction (default: `FALSE`).
* `--alignment` (Optional): Perform spectra alignment (default: `FALSE`).

### Output

The script produces the following output files:

* `<ID>_grouped_Spectrum_data_Quantified.rds`: RDS file containing the ASICS quantification object.
* `asics_normalized_metabolites.txt`: Text file containing normalized metabolite quantification data.
* `<ID>_quantified_metabolites.txt`: Text file containing transposed quantified metabolite data.

## Usage

### Prerequisites

Install the required R packages by running:

```bash
Rscript -e 'install.packages(c("BiocManager", "dplyr", "ggplot2", "DT", "visNetwork", "igraph", "svglite", "optparse"))'
Rscript -e 'BiocManager::install(c("PepsNMR", "ASICS"))'
```

### Running scripts

Navigate to your working directory and execute the realpath of the script's location with proper parameters by running the aforementioned commands.

Apart from main workflow scripts, supplementary `preprocessing_utils.R` script contains a collection of utility functions that serve different purposes in the spectral preprocesing and metabolites identification, including normalization and visualisation of FIDs/ Spectra.

Additional Notes:
* Adjust paths and filenames in the command based on your project structure.
* Ensure required dependencies (libcairo2-dev etc.) are installed and `preprocessing_utils.R` is available in the same location as all utilized scripts, as it contains the crucial functions for analysis.
* (Ideally) Run all scripts in provided R_utils docker container.
* Scripts should be run one by one in a subsequent order. However, there is a possibility to run any of them separately, so one has to be cautious while handling data input.
* Main functions originate from exisiting 1D 1H NMR processing packages: [ASICS](https://bioconductor.org/packages/release/bioc/html/ASICS.html), [PepsNMR](https://www.bioconductor.org/packages/release/bioc/html/PepsNMR.html) and [rnmr1d](https://cran.r-project.org/web/packages/Rnmr1D/index.html).

#### License

This project is licensed under the MIT License - see the [LICENSE.md](../LICENSE.md) file for details.
