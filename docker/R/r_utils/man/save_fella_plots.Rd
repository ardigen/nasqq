% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pathway_analysis_utils.R
\name{save_fella_plots}
\alias{save_fella_plots}
\title{Save FELLA plots}
\usage{
save_fella_plots(
  metabolites_kegg_enrichment,
  directory = "results/figures",
  nlimit = 250,
  plot_size = c(12, 8),
  show_legend = TRUE,
  plot_method = "diffusion"
)
}
\arguments{
\item{metabolites_kegg_enrichment}{A list containing the results of KEGG pathway enrichment analysis.}

\item{directory}{A character string specifying the directory where the plots will be saved. Defaults to "results/figures".}

\item{nlimit}{An integer specifying the maximum number of nodes in the results graph. Defaults to 250.}

\item{plot_size}{A numeric vector specifying the width and height of the plot in inches. Defaults to c(12, 8).}

\item{show_legend}{A logical value indicating whether to include a legend in the plot. Defaults to TRUE.}

\item{plot_method}{A character specifying the method used for generating the plot. Defaults to "diffusion".}
}
\description{
This function saves FELLA plots generated during KEGG pathway enrichment analysis.
}
