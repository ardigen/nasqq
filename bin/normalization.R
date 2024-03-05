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
    type = "character", dest = "spectra_ws", help = "Spectra post-WS or post WS/ B"
  ),
  make_option(
    c("--type_norm"),
    type = "character", dest = "type_norm", default = "pqn", help = "(Optional) Normalization type, one of: 'mean', 'pqn', 'median', 'firstquartile', 'peak'"
  ),
  make_option(
    c("--removal_regions"),
    type = "character", dest = "removal_regions", default = "list(Water = c(4.5, 5.1), Noise = c(0.0, 0.1))", help = "(Optional) Regions from spectra to be removed, by default Water and Noise around 0 ppms"
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

id <- opt$id
raw_rds <- opt$raw_rds
Spectrum_data_WS <- opt$spectra_ws
type_norm <- opt$type_norm
removal_regions <- eval(parse(text = opt$removal_regions))

if (is.null(id) ||
  is.null(raw_rds) ||
  is.null(Spectrum_data_WS)) {
  stop("Error: --id, --raw_rds, and --spectra_ws must be provided.", call. = FALSE)
}

fid_list <- readRDS(file = raw_rds)
FIDdata <- fid_list[["FIDdata"]]
FIDinfo <- fid_list[["FIDinfo"]]
sample_names <- rownames(FIDinfo)

Spectrum_data_WS <- readRDS(file = Spectrum_data_WS)
Spectrum_data_WS <- PepsNMR::RegionRemoval(Spectrum_data_WS, fromto.rr = removal_regions)
Spectrum_data_N <- PepsNMR::Normalization(Spectrum_data_WS, type.norm = type_norm)

melted_Spectrum_data_N <- reshape2::melt(
  Spectrum_data_N, c("sample_name", "ppm"),
  value.name = "intensity"
)

Normalized_FT_plots_list <- lapply(
  X = sample_names, FUN = function(x) {
    draw_plots_post_FT(
      df = melted_Spectrum_data_N %>%
        dplyr::filter(sample_name == x),
      sample_name = x, title = paste0(" spectrum after ", type_norm, " Normalization")
    )
  }
)

names(Normalized_FT_plots_list) <- sample_names

generate_stacked_pdf_plot(
  data = Spectrum_data_WS, file_name = "Spectrum_data_WS_stacked.pdf", ppm = Spectrum_data_WS %>%
    colnames() %>%
    as.numeric()
)
generate_stacked_pdf_plot(
  data = Spectrum_data_N, file_name = "Spectrum_data_N_stacked.pdf", ppm = Spectrum_data_N %>%
    colnames() %>%
    as.numeric()
)

save_plots(plots_list = Normalized_FT_plots_list, suffix = "_n_plot.svg")
save_rds(object = Normalized_FT_plots_list, filename = paste0(id, "_n_plots.rds"))
save_rds(object = Spectrum_data_N, filename = paste0(id, "_grouped_Spectrum_data_N.rds"))
write.table(
  x = spectra_peps_to_asics_format(Spectrum_data_N),
  file = "normalized_metabolites.txt",
  sep = "\t",
  row.names = TRUE
)
