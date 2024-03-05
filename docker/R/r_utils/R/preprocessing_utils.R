#!/usr/bin/env Rscript

suppressMessages({
  library(optparse)
  library(dplyr)
  library(PepsNMR)
  library(ASICS)
  library(DT)
  library(ggplot2)
  library(svglite)
  library(tidyr)
})

#' Create a vector of selected samples
#'
#' This function creates a vector of selected samples from a comma-separated string.
#' 
#' @param selected_sample_list A character string containing the selected sample IDs separated by commas.
#' @param split A character specifying the delimiter used to split the selected sample list. Defaults to ";".
#' @return A numeric vector containing the selected sample IDs.
#' @export
create_selected_samples_vector <- function(selected_sample_list, split = ";") {
  as.numeric(strsplit(x = selected_sample_list, split = split)[[1]])
}

#' Save plots as SVG files
#'
#' This function saves plots from a list of ggplot objects as SVG files.
#'
#' @param plots_list A list containing ggplot objects to be saved as plots.
#' @param directory A character specifying the directory where the plots will be saved. Defaults to "results/figures".
#' @param suffix A character specifying the suffix to be appended to the filenames of the saved plots. Defaults to "_raw_plot.svg".
#' @param plot_size A numeric vector specifying the width and height of the plot in inches. Defaults to c(10, 8).
#' @return NULL
#' @export
save_plots <- function(plots_list, directory = "results/figures", suffix = "_raw_plot.svg", plot_size = c(10, 8)) {
  dir.create(directory, showWarnings = FALSE, recursive = TRUE)
  lapply(
    names(plots_list),
    function(id) {
      ggsave(
        filename = file.path(directory, paste0(id, suffix)),
        plot = plots_list[[id]], width = plot_size[1], height = plot_size[2]
      )
    }
  )
}

#' Save RDS file
#'
#' This function saves an R object in RDS format.
#'
#' @param object The R object to be saved.
#' @param filename A character specifying the filename for the RDS file.
#' @param directory A character specifying the directory where the RDS file will be saved. Defaults to "results/tables".
#' @return NULL
#' @export
save_rds <- function(object, filename, directory = "results/tables") {
  dir.create(directory, showWarnings = FALSE, recursive = TRUE)
  saveRDS(object, file.path(directory, filename))
}

#' Check Pulse Programs
#'
#' This function checks the pulse programs used in the NMR spectra data.
#' 
#' @param spectra_path A character specifying the path to the directory containing the spectra files.
#' @param pulse_prog_value A character specifying the pulse program to check for.
#' @param sample_names A character vector containing the names of the samples.
#' @return A character vector containing the pulse programs for each sample.
#' @export
check_pulse_programs <- function(spectra_path, pulse_prog_value, sample_names) {
  pulse_program <- purrr::map_chr(
    .x = paste0(
      PepsNMR:::getDirsContainingFid(path = spectra_path),
      "/acqus"
    ),
    .f = function(file) {
      lines <- readLines(file)
      pulse_prog_line <- lines[grep(
        paste("\\$PULPROG", "=", sep = ""),
        lines
      )[1]]
      stringr::str_extract(pulse_prog_line, "(?<=<)[^>]+")
    }
  )
  names(pulse_program) <- sample_names
  is_valid_pulse_prog_value <- pulse_program == pulse_prog_value
  if (any(!is_valid_pulse_prog_value)) {
    warning(
      paste0("The data contains more pulse programs than ", pulse_prog_value, ". Removing different pulse program from analysis")
    )
    pulse_program <- pulse_program[is_valid_pulse_prog_value]
  }
  if (length(pulse_program) <
    1) {
    stop("Data is empty!")
  } else {
    return(pulse_program)
  }
}

#' Filtering FIDs Samples
#'
#' This function filters the FIDs (Free Induction Decay) data based on the selected sample list.
#'
#' @param FIDs A data frame containing the FIDs data.
#' @param selected_sample_list A character vector containing the names of the selected samples.
#' @param rm_duplicated_names A logical indicating whether to remove duplicated sample names. Defaults to FALSE.
#' @return A filtered data frame containing the FIDs data.
#' @export
filtering_FIDs_samples <- function(FIDs, selected_sample_list, rm_duplicated_names = FALSE) {
  FIDs <- FIDs %>%
    subset(
      ., rownames(.) %in%
        selected_sample_list
    )
  if (rm_duplicated_names) {
    duplicated_names <- FIDs %>%
      rownames() %>%
      duplicated()
    FIDs <- FIDs %>%
      subset(!duplicated_names)
  }
  return(FIDs)
}

#' Draw Raw Free Induction Decay (FID) Plot
#'
#' This function draws a plot of the raw Free Induction Decay (FID) data.
#' 
#' @param df A data frame containing the FID data.
#' @param time A numeric vector representing the time axis.
#' @param sample_name A character specifying the name of the sample.
#' @param title A character specifying the title of the plot. Defaults to "raw FID (real part)".
#' @param zoom A logical indicating whether to zoom the plot. Defaults to FALSE.
#' @param limit An integer specifying the limit for zooming the plot. Defaults to 300.
#' @return A ggplot object displaying the raw FID plot.
#' @export
draw_raw_FID <- function(df, time, sample_name, title = " raw FID (real part)", zoom = FALSE, limit = 300) {
  range <- dim(df)[2]
  if (zoom) {
    range <- limit
  }
  ggplot2::ggplot() +
    ggplot2::aes(
      x = time[0:range], y = Re(df[sample_name, 0:range]),
      color = "FID signal"
    ) +
    ggplot2::geom_line() +
    ggplot2::xlab(label = expression(paste("Time (", 10^3 * mu, "s)"))) +
    ggplot2::ylab(label = "Intensity") +
    ggplot2::ggtitle(label = paste0(sample_name, title)) +
    ggplot2::theme_classic() +
    ggplot2::scale_color_manual(name = "", values = c("black"))
}

#' Draw Compared Plots
#'
#' This function draws and compares two plots of FID data before and after group delay removal.
#'
#' @param df_before A data frame containing the FID data before group delay removal.
#' @param df_after A data frame containing the FID data after group delay removal.
#' @param time A numeric vector representing the time axis.
#' @param sample_name A character specifying the name of the sample.
#' @param title_before A character specifying the title for the plot before group delay removal. Defaults to "FID with the Group Delay (real part - zoom)".
#' @param title_after A character specifying the title for the plot after group delay removal. Defaults to "FID after Group Delay removal (real part - zoom)".
#' @param zoom A logical indicating whether to zoom the plot. Defaults to TRUE.
#' @param limit An integer specifying the limit for zooming the plot. Defaults to 300.
#' @return A grid.arrange object displaying the compared plots.
#' @export
draw_compared_plots <- function(df_before, df_after, time, sample_name, title_before = " FID with the Group Delay (real part - zoom)", title_after = " FID after Group Delay removal (real part - zoom)",
                                zoom = TRUE, limit = 300) {
  plot_before <- draw_raw_FID(df = df_before, time = time, sample_name = sample_name, title = title_before, zoom = zoom, limit = limit)
  plot_after <- draw_raw_FID(df = df_after, time = time, sample_name = sample_name, title = title_after, zoom = zoom, limit = limit)
  return(gridExtra::grid.arrange(plot_before, plot_after))
}

#' Draw Solvent Suppressed Plots
#'
#' This function draws plots of FID data with solvent residuals before and after suppression.
#'
#' @param df_before A data frame containing the FID data before solvent suppression.
#' @param df_after A data frame containing the FID data after solvent suppression.
#' @param sample_name A character specifying the name of the sample.
#' @param time A numeric vector representing the time axis.
#' @param limit An integer specifying the limit for zooming the plot. Defaults to 4000.
#' @param solvent_re A numeric vector representing the estimated solvent residuals.
#' @return A grid.arrange object displaying the plots.
#' @export
draw_solvent_suppresed_plots <- function(df_before = FIDdata_GDC, df_after = FIDdata_SS, sample_name, time = time, limit = 4000, solvent_re = SolventRe) {
  plot_before <- draw_raw_FID(
    df = df_before, time = time, sample_name = sample_name, title = " FID and solvent residuals signal before (real part - zoom)",
    zoom = TRUE, limit = limit
  ) +
    ggplot2::geom_line(
      mapping = ggplot2::aes(
        x = time[0:limit], y = Re(SolventRe[sample_name, 0:limit]),
        color = "red"
      )
    ) +
    ggplot2::scale_color_manual(
      name = "", labels = c("FID signal", "Estimated solvent residuals signal"),
      values = c("black", "red")
    )
  plot_after <- draw_raw_FID(
    df = df_after, time = time, sample_name = sample_name, title = " FID and solvent residuals signal after (real part - zoom)",
    zoom = TRUE, limit = limit
  ) +
    ggplot2::geom_line(
      mapping = ggplot2::aes(
        x = time[0:limit], y = rep(0, limit),
        color = "red"
      )
    ) +
    ggplot2::scale_color_manual(
      name = "", labels = c("FID signal", "Estimated solvent residuals signal"),
      values = c("black", "red")
    )
  gridExtra::grid.arrange(plot_before, plot_after)
}

#' Draw Plots Post Fourier Transform
#'
#' This function draws plots of FID data after Fourier Transform.
#'
#' @param df A data frame containing the FID data.
#' @param sample_name A character specifying the name of the sample.
#' @param title A character specifying the title of the plot. Defaults to "spectrum after Fourier Transform".
#' @return A ggplot object displaying the post Fourier Transform plot.
#' @export
draw_plots_post_FT <- function(df, sample_name, title = " spectrum after Fourier Transform") {
  ggplot2::ggplot() +
    ggplot2::aes(
      y = Re(df$intensity),
      x = df$ppm
    ) +
    ggplot2::geom_line() +
    ggplot2::xlab(label = "ppm") +
    ggplot2::ylab(label = "Intensity") +
    ggplot2::ggtitle(label = paste0(sample_name, title)) +
    ggplot2::theme_classic()
}

#' Plot Spectral Matrix for 1D NMR Data
#'
#' This function plots the spectral matrix for 1D NMR data.
#'
#' @param specmat A matrix containing the spectral data.
#' @param ppm A numeric vector representing the ppm axis.
#' @param ppm_lim A numeric vector specifying the limits of ppm to be plotted. Defaults to c(min(ppm), max(ppm)).
#' @param K A numeric value specifying a scaling factor. Defaults to 0.67.
#' @param pY A numeric value specifying the maximum intensity. Defaults to 1.
#' @param dppm_max A numeric value specifying the maximum deviation in ppm. Defaults to 0.2 * (max(ppm_lim) - min(ppm_lim)).
#' @param asym A numeric value specifying the asymmetry factor. Defaults to 1.
#' @param beta A numeric value specifying the beta coefficient. Defaults to 0.
#' @param cols A vector of colors for plotting. Defaults to NULL, which generates a rainbow palette.
#' @return A plot of the spectral matrix for 1D NMR data.
#' @export
plotSpecMatPeps <- function(Peps_df, ppm, ppm_lim = c(
                              min(ppm),
                              max(ppm)
                            ),
                            K = 0.67, pY = 1, dppm_max = 0.2 * (max(ppm_lim) -
                              min(ppm_lim)),
                            asym = 1, beta = 0, cols = NULL) {
  specmat <- Re(Peps_df)
  i2 <- which(ppm <= min(ppm_lim))[1]
  i1 <- length(which(ppm > max(ppm_lim)))
  ppm_sub <- ppm[i1:i2]
  specmat_sub <- specmat[, i1:i2]
  if (K == 0) {
    dppm_max <- 0
  }
  Ymax <- pY * max(specmat_sub)
  diffppm <- max(ppm_sub) -
    min(ppm_sub)
  Cy <- 1 - beta * (max(ppm_sub) -
    asym * dppm_max - ppm_sub) / (max(ppm_sub) -
    asym * dppm_max - min(ppm_sub))
  if (is.null(cols)) {
    cols <- grDevices::rainbow(
      dim(specmat_sub)[1],
      s = 0.8, v = 0.75
    )
  }
  graphics::plot(
    cbind(ppm_sub, specmat_sub[1, ]),
    xlim = rev(ppm_lim),
    ylim = c(0, Ymax),
    type = "h", col = "white", xlab = "ppm", ylab = "Intensity (u.a)"
  )
  graphics::segments(
    max(ppm_sub) -
      asym * dppm_max, K * Ymax, min(ppm_sub) +
      dppm_max, (1 - beta) * K * Ymax,
    col = "lightgrey"
  )
  graphics::segments(
    max(ppm_sub),
    0, min(ppm_sub),
    0,
    col = "lightgrey"
  )
  graphics::segments(
    max(ppm_sub),
    0, max(ppm_sub) -
      asym * dppm_max, K * Ymax,
    col = "lightgrey"
  )
  graphics::segments(
    min(ppm_sub) +
      dppm_max, (1 - beta) * K * Ymax, min(ppm_sub),
    0,
    col = "lightgrey"
  )
  for (i in 1:dim(specmat_sub)[1]) {
    dppm <- dppm_max * (i - 1) / (dim(specmat_sub)[1] -
      1)
    ppmi <- ppm_sub * (1 - (1 + asym) * dppm / diffppm) + dppm * (1 + (1 + asym) * min(ppm_sub) / diffppm)
    y_offset <- K * Ymax * Cy * (i - 1) / (dim(specmat_sub)[1] -
      1)
    graphics::lines(
      cbind(ppmi, specmat_sub[i, ] + y_offset),
      col = cols[i]
    )
  }
}

#' Generate Stacked PDF Plot
#'
#' This function generates a stacked PDF plot.
#'
#' @param data A data frame containing the spectral matrix data.
#' @param directory A character specifying the directory for saving the plot. Defaults to "results/figures/".
#' @param file_name A character specifying the name of the PDF file.
#' @param ppm A numeric vector representing the ppm axis.
#' @param width A numeric value specifying the width of the PDF plot. Defaults to 16.
#' @param height A numeric value specifying the height of the PDF plot. Defaults to 10.
#' @return A stacked PDF plot saved in the specified directory.
#' @export
generate_stacked_pdf_plot <- function(data, directory = "results/figures/", file_name, ppm, width = 16, height = 10) {
  dir.create(directory, showWarnings = FALSE, recursive = TRUE)
  pdf(
    file = paste0(directory, file_name),
    width = width, height = height
  )
  plotSpecMatPeps(Peps_df = data, ppm = ppm)
  dev.off()
}

#' Return Samples to Reverse
#' 
#' This function identifies samples with negative percentages exceeding a specified threshold in a matrix and returns their names.
#' 
#' @param matrix_ZOPC A matrix containing data where negative percentages are to be checked.
#' @param threshold A numeric value specifying the threshold percentage. Samples with negative percentages greater than this threshold will be returned. Defaults to 50.
#' @return A character vector containing the names of samples with negative percentages exceeding the threshold.
#' @export
return_samples_to_reverse <- function(matrix_ZOPC, threshold = 50) {
  negative_percentages <- rowSums(Re(matrix_ZOPC) < 0) / ncol(matrix_ZOPC) * 100
  rownames(matrix_ZOPC)[negative_percentages > threshold]
}

#' Reverse Selected Samples Axis
#' 
#' This function reverses the selected samples' axis by multiplying their values by -1 in a matrix.
#' 
#' @param selected_samples_to_reverse A character vector containing the names of samples to be reversed.
#' @param matrix_ZOPC A matrix containing data where the selected samples' axis will be reversed.
#' @return A matrix with the selected samples' axis reversed.
#' @export
reverse_selected_samples_axis <- function(selected_samples_to_reverse, matrix_ZOPC) {
  selected_samples_to_reverse <- selected_samples_to_reverse %>%
    as.character()
  matrix_ZOPC[selected_samples_to_reverse, ] <- -1 * matrix_ZOPC[selected_samples_to_reverse, ]
  return(matrix_ZOPC)
}

#' Spectra PepsNMR to ASICs Format
#' 
#' This function transforms spectra data from PepsNMR package to ASICs format.
#' 
#' @param peps_spectra A matrix containing spectra data in PEPs format.
#' @return A data frame with the spectra transformed to ASICs format.
#' @export
spectra_peps_to_asics_format <- function(peps_spectra) {
  transformed_spectra <- peps_spectra %>%
    Re() %>%
    t() %>%
    as.data.frame()
  transformed_spectra <- transformed_spectra[nrow(transformed_spectra):1, ]
  return(transformed_spectra)
}
