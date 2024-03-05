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
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

id <- opt$id
raw_rds <- opt$raw_rds

if (is.null(id) ||
  is.null(raw_rds)) {
  stop("Error: --id and --raw_rds must be provided.", call. = FALSE)
}

fid_list <- readRDS(file = raw_rds)
FIDdata <- fid_list[["FIDdata"]]
FIDinfo <- fid_list[["FIDinfo"]]

sample_names <- rownames(FIDinfo)
time <- as.numeric(colnames(FIDdata)) * 1000

FIDdata_GDC <- PepsNMR::GroupDelayCorrection(Fid_data = FIDdata, Fid_info = FIDinfo)

gdc_compared_plots_list <- lapply(sample_names, draw_compared_plots, df_before = FIDdata, df_after = FIDdata_GDC, time = time)
names(gdc_compared_plots_list) <- sample_names

save_plots(plots_list = gdc_compared_plots_list, suffix = "_gdc_plot.svg")
save_rds(object = gdc_compared_plots_list, filename = paste0(id, "_gdc_compared_plots.rds"))
save_rds(object = FIDdata_GDC, filename = paste0(id, "_grouped_FIDdata_GDC.rds"))
