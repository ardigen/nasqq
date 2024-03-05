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
    c("--spectra_ir"),
    type = "character", dest = "spectra_ir", help = "Spectra post-IR"
  ),
  make_option(
    c("--lambda_bc"),
    type = "numeric", dest = "lambda_bc", default = 5e+06, help = "(Optional) lambda_bc"
  ),
  make_option(
    c("--p_bc"),
    type = "numeric", dest = "p_bc", default = 1e-04, help = "(Optional) p_bc"
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

id <- opt$id
raw_rds <- opt$raw_rds
Spectrum_data_IR <- opt$spectra_ir
lambda_bc <- opt$lambda_bc
p_bc <- opt$p_bc

if (is.null(id) ||
  is.null(raw_rds) ||
  is.null(Spectrum_data_IR)) {
  stop("Error: --id, --raw_rds, and --spectra_ir must be provided.", call. = FALSE)
}

fid_list <- readRDS(file = raw_rds)
FIDdata <- fid_list[["FIDdata"]]
FIDinfo <- fid_list[["FIDinfo"]]
sample_names <- rownames(FIDinfo)

Spectrum_data_IR <- readRDS(file = Spectrum_data_IR)

BC_res <- PepsNMR::BaselineCorrection(Spectrum_data_IR, returnBaseline = TRUE, ptw.bc = TRUE, lambda.bc = lambda_bc, p.bc = p_bc)

Spectrum_data_BC <- BC_res[["Spectrum_data"]]
Baseline <- BC_res[["Baseline"]]

melted_Spectrum_data_BC <- reshape2::melt(
  Spectrum_data_BC, c("sample_name", "ppm"),
  value.name = "intensity"
)
melted_Spectrum_data_IR <- reshape2::melt(
  Spectrum_data_IR, c("sample_name", "ppm"),
  value.name = "intensity"
)

BC_FT_plots_list <- lapply(
  X = sample_names, FUN = function(x) {
    plot_before <- draw_plots_post_FT(
      df = melted_Spectrum_data_IR %>%
        dplyr::filter(sample_name == x),
      sample_name = x, title = " spectrum before Baseline Correction"
    ) +
      ggplot2::geom_line(mapping = ggplot2::aes(y = Baseline[, x], color = "baseline")) +
      ggplot2::scale_color_manual(name = "", values = c(baseline = "red"))
    plot_after <- draw_plots_post_FT(
      df = melted_Spectrum_data_BC %>%
        dplyr::filter(sample_name == x),
      sample_name = x, title = " spectrum after Baseline Correction"
    )
    grid_plots <- gridExtra::grid.arrange(plot_before, plot_after)
    return(grid_plots)
  }
)
names(BC_FT_plots_list) <- sample_names

save_plots(plots_list = BC_FT_plots_list, suffix = "_bc_plot.svg")
save_rds(object = BC_FT_plots_list, filename = paste0(id, "_bc_compared_plots.rds"))
save_rds(object = Spectrum_data_BC, filename = paste0(id, "_grouped_Spectrum_data_BC.rds"))
