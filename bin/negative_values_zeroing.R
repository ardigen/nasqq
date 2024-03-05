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
    c("--raw_rds"),
    type = "character", dest = "raw_rds", help = "Raw data RDS"
  ),
  make_option(
    c("--spectra_bc"),
    type = "character", dest = "spectra_bc", help = "Spectra post-BC"
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

id <- opt$id
raw_rds <- opt$raw_rds
Spectrum_data_BC <- opt$spectra_bc

if (is.null(id) ||
  is.null(raw_rds) ||
  is.null(Spectrum_data_BC)) {
  stop("Error: --id, --raw_rds and --spectra_bc must be provided.", call. = FALSE)
}

fid_list <- readRDS(file = raw_rds)
FIDdata <- fid_list[["FIDdata"]]
FIDinfo <- fid_list[["FIDinfo"]]
sample_names <- rownames(FIDinfo)

Spectrum_data_BC <- readRDS(file = Spectrum_data_BC)
Spectrum_data_NVZ <- PepsNMR::NegativeValuesZeroing(Spectrum_data_BC)

melted_Spectrum_data_NVZ <- reshape2::melt(
  Spectrum_data_NVZ, c("sample_name", "ppm"),
  value.name = "intensity"
)
NVZ_FT_plots_list <- lapply(
  X = sample_names, FUN = function(x) {
    draw_plots_post_FT(
      df = melted_Spectrum_data_NVZ %>%
        dplyr::filter(sample_name == x),
      sample_name = x, title = " spectrum after Negative Values Zeroing"
    )
  }
)
names(NVZ_FT_plots_list) <- sample_names

save_plots(plots_list = NVZ_FT_plots_list, suffix = "_nvz_plot.svg")
save_rds(object = NVZ_FT_plots_list, filename = paste0(id, "_nvz_plots.rds"))
save_rds(object = Spectrum_data_NVZ, filename = paste0(id, "_grouped_Spectrum_data_NVZ.rds"))
