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
    c("--fid_zf"),
    type = "character", dest = "fid_zf", help = "FID data post-ZF"
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

id <- opt$id
raw_rds <- opt$raw_rds
FIDdata_ZF <- opt$fid_zf

if (is.null(id) ||
  is.null(raw_rds) ||
  is.null(FIDdata_ZF)) {
  stop("Error: --id, --raw_rds and --fid_zf must be provided.", call. = FALSE)
}

fid_list <- readRDS(file = raw_rds)
FIDdata <- fid_list[["FIDdata"]]
FIDinfo <- fid_list[["FIDinfo"]]
sample_names <- rownames(FIDinfo)

FIDdata_ZF <- readRDS(file = FIDdata_ZF)

RawSpect_data_FT <- PepsNMR::FourierTransform(FIDdata_ZF, FIDinfo)
melted_RawSpect_data_FT <- reshape2::melt(
  RawSpect_data_FT, c("sample_name", "ppm"),
  value.name = "intensity"
)

raw_FT_plots_list <- lapply(
  X = sample_names, FUN = function(x) {
    draw_plots_post_FT(
      df = melted_RawSpect_data_FT |>
        dplyr::filter(sample_name == x),
      sample_name = x
    )
  }
)
names(raw_FT_plots_list) <- sample_names

save_plots(plots_list = raw_FT_plots_list, suffix = "_ft_plot.svg")
save_rds(object = raw_FT_plots_list, filename = paste0(id, "_fourier_compared_plots.rds"))
save_rds(object = RawSpect_data_FT, filename = paste0(id, "_grouped_RawSpect_data_FT.rds"))
