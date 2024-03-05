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
    c("--raw_spect_ft"),
    type = "character", dest = "raw_spect_ft", help = "Raw spectra post-FT"
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

id <- opt$id
raw_rds <- opt$raw_rds
RawSpect_data_FT <- opt$raw_spect_ft

if (is.null(id) ||
  is.null(raw_rds) ||
  is.null(RawSpect_data_FT)) {
  stop("Error: --id, --raw_rds and --raw_spect_ft must be provided.", call. = FALSE)
}

fid_list <- readRDS(file = raw_rds)
FIDdata <- fid_list[["FIDdata"]]
FIDinfo <- fid_list[["FIDinfo"]]
sample_names <- rownames(FIDinfo)

RawSpect_data_FT <- readRDS(file = RawSpect_data_FT)

Spectrum_data_ZOPC <- PepsNMR::ZeroOrderPhaseCorrection(RawSpect_data_FT)
melted_Spectrum_data_ZOPC <- reshape2::melt(
  Spectrum_data_ZOPC, c("sample_name", "ppm"),
  value.name = "intensity"
)
ZOPC_FT_plots_list <- lapply(
  X = sample_names, FUN = function(x) {
    draw_plots_post_FT(
      df = melted_Spectrum_data_ZOPC %>%
        dplyr::filter(sample_name == x),
      sample_name = x, title = " spectrum after Zero Order Phase Correction"
    )
  }
)
names(ZOPC_FT_plots_list) <- sample_names

save_plots(plots_list = ZOPC_FT_plots_list, suffix = "_zopc_plot.svg")
save_rds(object = ZOPC_FT_plots_list, filename = paste0(id, "_zopc_plots.rds"))
save_rds(object = Spectrum_data_ZOPC, filename = paste0(id, "_grouped_Spectrum_data_ZOPC.rds"))
