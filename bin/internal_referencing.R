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
    c("--spectra_zopc"),
    type = "character", dest = "spectra_zopc", help = "Spectra_post-ZOPC"
  ),
  make_option(
    c("--target_value"),
    type = "numeric", dest = "target_value", default = 0, help = "(Optional) target_value"
  ),
  make_option(
    c("--fromto_rc"),
    type = "character", dest = "fromto_rc", help = "(Optional) fromto_RC"
  ),
  make_option(
    c("--reverse_axis_samples"),
    type = "character", dest = "reverse_axis_samples", default ="selected", help = "(Optional) Whether reverse axis for all or selected samples"
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

id <- opt$id
raw_rds <- opt$raw_rds
Spectrum_data_ZOPC <- opt$spectra_zopc
target_value <- as.numeric(opt$target_value)
fromto_RC <- opt$fromto_rc
reverse_axis_samples <- opt$reverse_axis_samples

if (target_value != 0) {
  range_type <- "window"
  fromto_RC <- list(create_selected_samples_vector(fromto_RC))
} else {
  range_type <- "nearvalue"
  fromto_RC <- NULL
}

if (is.null(id) ||
  is.null(raw_rds) ||
  is.null(Spectrum_data_ZOPC)) {
  stop("Error: --id, --raw_rds, --spectra_zopc must be provided.", call. = FALSE)
}

fid_list <- readRDS(file = raw_rds)
FIDdata <- fid_list[["FIDdata"]]
FIDinfo <- fid_list[["FIDinfo"]]
sample_names <- rownames(FIDinfo)

Spectrum_data_ZOPC <- readRDS(file = Spectrum_data_ZOPC)

if (reverse_axis_samples == "selected")
{
    selected_samples_to_reverse <- return_samples_to_reverse(Spectrum_data_ZOPC)
    if (length(selected_samples_to_reverse) > 0)
    {
        Spectrum_data_ZOPC <- reverse_selected_samples_axis(selected_samples_to_reverse = selected_samples_to_reverse, matrix_ZOPC = Spectrum_data_ZOPC)
    }
} else if (reverse_axis_samples == "all")
{
    Spectrum_data_ZOPC <- reverse_selected_samples_axis(selected_samples_to_reverse = rownames(Spectrum_data_ZOPC), matrix_ZOPC = Spectrum_data_ZOPC)
}

IR_res <- PepsNMR::InternalReferencing(
  Spectrum_data_ZOPC, FIDinfo,
  ppm.value = target_value, rowindex_graph = c(1, 2),
  range = range_type, fromto.RC = fromto_RC
)

Spectrum_data_IR <- IR_res$Spectrum_data
ppmvalues <- as.numeric(colnames(Spectrum_data_IR))
IR_point <- which(
  abs(ppmvalues - target_value) ==
    min(abs(ppmvalues - target_value))
)

melted_Spectrum_data_IR <- reshape2::melt(
  Spectrum_data_IR, c("sample_name", "ppm"),
  value.name = "intensity"
)

IR_FT_plots_list <- lapply(
  X = sample_names, FUN = function(x) {
    IR_plot <- draw_plots_post_FT(
      df = melted_Spectrum_data_IR %>%
        dplyr::filter(sample_name == x),
      sample_name = x, title = " spectrum after IR"
    )
    return(
      IR_plot + ggplot2::geom_vline(
        ggplot2::aes(
          xintercept = ppmvalues[IR_point],
          color = "peak location"
        )
      ) +
        ggplot2::scale_color_manual(name = "", values = c(`peak location` = "red"))
    )
  }
)
names(IR_FT_plots_list) <- sample_names

save_plots(plots_list = IR_FT_plots_list, suffix = "_ir_plot.svg")
save_rds(object = IR_FT_plots_list, filename = paste0(id, "_ir_compared_plots.rds"))
save_rds(object = Spectrum_data_IR, filename = paste0(id, "_grouped_Spectrum_data_IR.rds"))
