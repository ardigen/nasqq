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
    c("--spectra_ws"),
    type = "character", dest = "spectra_ws", help = "Spectra post-WS"
  ),
  make_option(
    c("--intmeth"),
    type = "character", default = "t", dest = "intmeth", help = "(Optional) Type of bucketing, rectangular or trapezoidal: one of r, t"
  ),
  make_option(
    c("--width"),
    type = "logical", default = FALSE, dest = "width", help = "(Optional) Whether mb represents width or not."
  ),
  make_option(
    c("--mb"),
    type = "integer", default = 5000, dest = "mb", help = "(Optional) Number or width of buckets, depending on width argument"
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

id <- opt$id
raw_rds <- opt$raw_rds
Spectrum_data_WS <- opt$spectra_ws
intmeth <- opt$intmeth
width <- opt$width
mb <- opt$mb


if (is.null(id) ||
  is.null(raw_rds) ||
  is.null(Spectrum_data_WS)) {
  stop("Error: --id, --raw_rds and --spectra_ws must be provided.", call. = FALSE)
}

fid_list <- readRDS(file = raw_rds)
FIDdata <- fid_list[["FIDdata"]]
FIDinfo <- fid_list[["FIDinfo"]]
sample_names <- rownames(FIDinfo)

Spectrum_data_WS <- readRDS(file = Spectrum_data_WS)
Spectrum_data_B <- PepsNMR::Bucketing(Spectrum_data_WS, intmeth = intmeth, mb = mb, width = width)

melted_Spectrum_data_WS <- reshape2::melt(
  Spectrum_data_WS, c("sample_name", "ppm"),
  value.name = "intensity"
)
melted_Spectrum_data_B <- reshape2::melt(
  Spectrum_data_B, c("sample_name", "ppm"),
  value.name = "intensity"
)

Bucketed_FT_plots_list <- lapply(
  X = sample_names, FUN = function(x) {
    plot_before <- draw_plots_post_FT(
      df = melted_Spectrum_data_WS %>%
        dplyr::filter(sample_name == x),
      sample_name = x, title = " spectrum after Window Selection"
    )
    plot_after <- draw_plots_post_FT(
      df = melted_Spectrum_data_B %>%
        dplyr::filter(sample_name == x),
      sample_name = x, title = " spectrum after Bucketing"
    )
    gridExtra::grid.arrange(plot_before, plot_after)
  }
)
names(Bucketed_FT_plots_list) <- sample_names

save_plots(plots_list = Bucketed_FT_plots_list, suffix = "_bucketed_plot.svg")
save_rds(object = Bucketed_FT_plots_list, filename = paste0(id, "_B_compared_plots.rds"))
save_rds(object = Spectrum_data_B, filename = paste0(id, "_grouped_Spectrum_data_B.rds"))
