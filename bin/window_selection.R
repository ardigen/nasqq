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
    c("--spectra_nvz"),
    type = "character", dest = "spectra_nvz", help = "Spectra post NVZ or post NVZ/ W"
  ),
  make_option(
    c("--from_ws"),
    type = "numeric", default = 10, dest = "from_ws", help = "(Optional) Limit for window from ppm"
  ),
  make_option(
    c("--to_ws"),
    type = "numeric", default = 0, dest = "to_ws", help = "(Optional) Limit for window to ppm"
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

id <- opt$id
raw_rds <- opt$raw_rds
Spectrum_data_NVZ <- opt$spectra_nvz
from_ws <- opt$from_ws
to_ws <- opt$to_ws

if (is.null(id) ||
  is.null(Spectrum_data_NVZ)) {
  stop("Error: --id and --spectra_nvz must be provided.", call. = FALSE)
}

Spectrum_data_NVZ <- readRDS(file = Spectrum_data_NVZ)
Spectrum_data_WS <- PepsNMR::WindowSelection(Spectrum_data_NVZ, from.ws = from_ws, to.ws = to_ws)

save_rds(object = Spectrum_data_WS, filename = paste0(id, "_grouped_Spectrum_data_WS.rds"))
