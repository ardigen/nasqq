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
    c("--fid_a"),
    type = "character", dest = "fid_a", help = "FID data post-A"
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

id <- opt$id
raw_rds <- opt$raw_rds
FIDdata_A <- opt$fid_a

if (is.null(id) ||
  is.null(raw_rds) ||
  is.null(FIDdata_A)) {
  stop("Error: --id, --raw_rds and --fid_a must be provided.", call. = FALSE)
}

fid_list <- readRDS(file = raw_rds)
FIDdata <- fid_list[["FIDdata"]]
FIDinfo <- fid_list[["FIDinfo"]]

sample_names <- rownames(FIDinfo)
time <- as.numeric(colnames(FIDdata)) * 1000

FIDdata_A <- readRDS(file = FIDdata_A)
FIDdata_ZF <- PepsNMR::ZeroFilling(FIDdata_A, fn = ncol(FIDdata_A))

zf_compared_plots_list <- lapply(
  sample_names, draw_compared_plots,
  df_before = FIDdata_A, df_after = FIDdata_ZF, time = time, title_before = " FID before Zero Filling",
  title_after = " FID after Zero Filling", zoom = FALSE
)
names(zf_compared_plots_list) <- sample_names

save_plots(plots_list = zf_compared_plots_list, suffix = "_zf_plot.svg")
save_rds(object = zf_compared_plots_list, filename = paste0(id, "_zerofilling_compared_plots.rds"))
save_rds(object = FIDdata_ZF, filename = paste0(id, "_grouped_FIDdata_ZF.rds"))
