#!/usr/bin/env Rscript

suppressMessages({
  library(optparse)
  library(dplyr)
  library(PepsNMR)
  library(ASICS)
  library(DT)
  library(ggplot2)
  library(rutils)
  library(svglite)
  library(tidyr)
})

option_list <- list(
  make_option(
    c("--id"),
    type = "character", dest = "id", help = "ID"
  ),
  make_option(
    c("--dir-path"),
    type = "character", dest = "dir_path", help = "Directory path"
  ),
  make_option(
    c("--peps-format-file"),
    type = "character", dest = "peps_format_file", help = "PepsNMR format file path"
  ),
  make_option(
    c("--ncores"),
    type = "integer", dest = "ncores", help = "Number of cores"
  ),
  make_option(
    c("--quantif-method"),
    type = "character", default = "both", dest = "quantif_method", help = "(Optional) Quantification method one of: FWER, Lasso, or both"
  ),
  make_option(
    c("--reference"),
    type = "integer", default = NULL, dest = "reference", help = "(Optional) Reference spectrum for alignment"
  ),
  make_option(
    c("--normalisation"),
    action = "store_true", default = FALSE, dest = "normalisation", help = "(Optional) Perform spectra normalization"
  ),
  make_option(
    c("--baseline-correction"),
    action = "store_true", default = FALSE, dest = "baseline_correction", help = "(Optional) Perform spectra baseline correction"
  ),
  make_option(
    c("--alignment"),
    action = "store_true", default = FALSE, dest = "alignment", help = "(Optional) Perform spectra alignment"
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

id <- opt$id
dir_path <- opt$dir_path
peps_format_file <- opt$peps_format_file
ncores <- opt$ncores
quantif_method <- opt$quantif_method
reference <- ifelse(opt$reference == "NULL", NULL, opt$reference)
normalisation <- opt$normalisation
baseline_correction <- opt$baseline_correction
alignment <- opt$alignment

if (is.null(id) ||
  is.null(dir_path) ||
  is.null(peps_format_file) ||
  is.null(ncores)) {
  stop("Error: --id, --dir-path, --peps-format-file, and --ncores must be provided.", call. = FALSE)
}

imported_peps <- ASICS::importSpectra(
  name.dir = dir_path, name.file = peps_format_file, type.import = "txt", normalisation = normalisation, baseline.correction = baseline_correction,
  alignment = alignment, ncores = ncores, verbose = TRUE, reference = reference, header = TRUE, check.names = FALSE
)

spectra_obj <- ASICS::createSpectra(imported_peps)

asics_obj <- ASICS::ASICS(
  spectra_obj = spectra_obj, quantif.method = quantif_method, ncores = ncores, verbose = TRUE, joint.align = alignment,
  seed = 1234
)

asics_obj@sample.name <- spectra_obj@sample.name
names(asics_obj@quantification) <- asics_obj@sample.name

save_rds(object = asics_obj, filename = paste0(id, "_grouped_Spectrum_data_Quantified.rds"))
data.table::fwrite(
  x = asics_obj@quantification, file = "results/tables/asics_normalized_metabolites.txt", sep = ",", col.names = TRUE,
  row.names = TRUE
)

quant <- asics_obj@quantification %>%
  tibble::rownames_to_column(var = "metabolite")

transposed_quant <- quant %>%
  tidyr::pivot_longer(
    cols = c(-metabolite),
    names_to = "patient_no"
  ) %>%
  tidyr::pivot_wider(names_from = "metabolite") %>%
  dplyr::mutate(patient_no = as.numeric(patient_no))

data.table::fwrite(
  x = transposed_quant, file = paste0(id, "_quantified_metabolites.txt"),
  sep = ",", col.names = TRUE
)
