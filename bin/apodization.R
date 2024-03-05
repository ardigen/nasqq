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
    c("--ss_res"),
    type = "character", dest = "ss_res", help = "FID data post-SS"
  ),
  make_option(
    c("--raw_rds"),
    type = "character", dest = "raw_rds", help = "Raw data RDS"
  ),
  make_option(
    c("--pulse_prog_value"),
    type = "character", dest = "pulse_prog_value", default = "unknown", help = "(Optional) pulse program value"
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

id <- opt$id
SS_res <- opt$ss_res
raw_rds <- opt$raw_rds
pulse_prog_value <- opt$pulse_prog_value

if (is.null(id) ||
  is.null(SS_res) ||
  is.null(raw_rds)) {
  stop("Error: --id, --SS_res, and --raw_rds must be provided.", call. = FALSE)
}

fid_list <- readRDS(file = raw_rds)
FIDdata <- fid_list[["FIDdata"]]
FIDinfo <- fid_list[["FIDinfo"]]

sample_names <- rownames(FIDinfo)
time <- as.numeric(colnames(FIDdata)) * 1000

SS_res <- readRDS(file = SS_res)
FIDdata_SS <- SS_res$Fid_data
SolventRe <- SS_res$SolventRe

expLB <- dplyr::case_when(
  grepl(pattern = "noesy", x = pulse_prog_value) ~
    0.03, grepl(pattern = "cpmg", x = pulse_prog_value) ~
    -0.01, TRUE ~ 0.3
)

FIDdata_A <- PepsNMR::Apodization(FIDdata_SS, FIDinfo, expLB = expLB)

apodization_compared_plots_list <- lapply(
  sample_names, draw_compared_plots,
  df_before = FIDdata_SS, df_after = FIDdata_A, time = time, title_before = " FID before Apodization",
  title_after = " FID after Apodization", zoom = FALSE
)
names(apodization_compared_plots_list) <- sample_names

save_plots(plots_list = apodization_compared_plots_list, suffix = "_apodization_plot.svg")
save_rds(object = apodization_compared_plots_list, filename = paste0(id, "_apodization_compared_plots.rds"))
save_rds(object = FIDdata_A, filename = paste0(id, "_grouped_FIDdata_A.rds"))
