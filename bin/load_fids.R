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
    type = "character", help = "ID"
  ),
  make_option(
    c("--raw_data_path"),
    type = "character", help = "Raw data path"
  ),
  make_option(
    c("--pulse_program"),
    type = "character", help = "Pulse program"
  ),
  make_option(
    c("--selected_sample_names"),
    type = "character", default = "all", help = "(Optional) Selected sample names"
  ),
  make_option(
    c("--rm_duplicated_names"),
    type = "logical", default = FALSE, help = "(Optional) Remove duplicated names"
  )
)
opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$id) ||
  is.null(opt$raw_data_path) ||
  is.null(opt$pulse_program)) {
  stop("Error: At least --id, --raw_data_path, and --pulse_program must be supplied.", call. = FALSE)
}

id <- opt$id
path_raw_data <- opt$raw_data_path
pulse_prog_value <- opt$pulse_program
selected_sample_names <- opt$selected_sample_names
rm_duplicated_names <- opt$rm_duplicated_names

fid_list <- PepsNMR::ReadFids(path = path_raw_data, l = 1, subdirs = FALSE, dirs.names = TRUE, verbose = TRUE)

selected_sample_list <- tryCatch(
  expr = check_pulse_programs(
    spectra_path = path_raw_data, pulse_prog_value = pulse_prog_value, sample_names = fid_list$Fid_info %>%
      rownames() %>%
      as.character()
  ),
  error = function(e) {
    cat("Error occurred: ", conditionMessage(e), "\n")
  }
)

if (selected_sample_names != "all") {
  selected_sample_list <- selected_sample_list %>%
    subset(
      ., names(.) %in%
        create_selected_samples_vector(selected_sample_names)
    )
}

cat(
  "Sample names with consistent pulse program:", selected_sample_list %>%
    names(), "\n"
)

FIDdata <- fid_list$Fid_data %>%
  filtering_FIDs_samples(
    selected_sample_list = selected_sample_list %>%
      names() %>%
      as.numeric(), rm_duplicated_names = rm_duplicated_names
  )
FIDinfo <- fid_list$Fid_info %>%
  filtering_FIDs_samples(
    selected_sample_list = selected_sample_list %>%
      names() %>%
      as.numeric(), rm_duplicated_names = rm_duplicated_names
  )

save_rds(
  object = list(FIDdata = fid_list$Fid_data, FIDinfo = fid_list$Fid_info),
  filename = paste0(id, "_original_fid_list.rds")
)
save_rds(
  object = list(FIDdata = FIDdata, FIDinfo = FIDinfo),
  filename = paste0(id, "_selected_fid_list.rds")
)
