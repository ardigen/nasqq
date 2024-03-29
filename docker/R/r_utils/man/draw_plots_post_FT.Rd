% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/preprocessing_utils.R
\name{draw_plots_post_FT}
\alias{draw_plots_post_FT}
\title{Draw Plots Post Fourier Transform}
\usage{
draw_plots_post_FT(
  df,
  sample_name,
  title = " spectrum after Fourier Transform"
)
}
\arguments{
\item{df}{A data frame containing the FID data.}

\item{sample_name}{A character specifying the name of the sample.}

\item{title}{A character specifying the title of the plot. Defaults to "spectrum after Fourier Transform".}
}
\value{
A ggplot object displaying the post Fourier Transform plot.
}
\description{
This function draws plots of FID data after Fourier Transform.
}
