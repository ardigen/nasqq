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

time <- as.numeric(colnames(FIDdata)) * 1000
sample_names <- rownames(FIDinfo)

raw_plots_list <- lapply(sample_names, draw_raw_FID, df = FIDdata, time = time)
names(raw_plots_list) <- sample_names

save_plots(plots_list = raw_plots_list)
save_rds(object = raw_plots_list, filename = paste0(id, "_raw_plots_list.rds"))
