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
    c("--fid_gdc"),
    type = "character", dest = "fid_gdc", help = "FID data post-GDC"
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

id <- opt$id
raw_rds <- opt$raw_rds
FIDdata_GDC <- opt$fid_gdc

if (is.null(id) ||
  is.null(raw_rds) ||
  is.null(FIDdata_GDC)) {
  stop("Error: --id, --raw_rds and --fid_gdc must be provided.", call. = FALSE)
}

fid_list <- readRDS(file = raw_rds)
FIDdata <- fid_list[["FIDdata"]]
FIDinfo <- fid_list[["FIDinfo"]]

sample_names <- rownames(FIDinfo)
time <- as.numeric(colnames(FIDdata)) * 1000

FIDdata_GDC <- readRDS(file = FIDdata_GDC)

SS_res <- PepsNMR::SolventSuppression(Fid_data = FIDdata_GDC, returnSolvent = TRUE)
FIDdata_SS <- SS_res$Fid_data
SolventRe <- SS_res$SolventRe

ss_compared_plots_list <- lapply(
  sample_names, draw_solvent_suppresed_plots,
  df_before = FIDdata_GDC, df_after = FIDdata_SS, time = time, limit = 4000,
  solvent_re = SolventRe
)
names(ss_compared_plots_list) <- sample_names

save_plots(plots_list = ss_compared_plots_list, suffix = "_ss_plot.svg")
save_rds(object = ss_compared_plots_list, filename = paste0(id, "_ss_compared_plots.rds"))
save_rds(object = SS_res, filename = paste0(id, "_grouped_FIDdata_SS.rds"))
