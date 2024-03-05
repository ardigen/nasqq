#!/usr/bin/env Rscript

suppressMessages({
  library(optparse)
  library(FELLA)
  library(dplyr)
  library(visNetwork)
  library(igraph)
  library(rutils)
})

option_list <- list(
  make_option(
    c("--input_file_path"),
    type = "character", dest = "input_file_path", help = "Path to the input file from multi/univarite module"
  ),
  make_option(
    c("--top_n"),
    type = "integer", default = 20, dest = "top_n", help = "Number of Metabolites to include in enrichment"
  ),
  make_option(
    c("--kegg_org_id"),
    type = "character", default = "hsa", dest = "kegg_org_id", help = "KEGG organism ID"
  )
)

opt_parser <- OptionParser(usage = "Usage: %prog [options]", option_list = option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$input_file_path) ||
  is.null(opt$top_n) ||
  is.null(opt$kegg_org_id)) {
  stop("Error: --input_file_path, --top_n, and --kegg_org_id must be provided.", call. = FALSE)
}

input_file_path <- opt$input_file_path
top_n <- opt$top_n
kegg_org_id <- opt$kegg_org_id

metabolites <- data.table::fread(input = input_file_path) %>%
  head(top_n) %>%
  dplyr::pull(Feature)

metabolites_kegg_ids <- translate_ASICS_to_KEGG_ids(metabo_list = metabolites)

tmpdir <- paste0(tempdir(), "/database_kegg")
unlink(tmpdir, recursive = TRUE)
graph <- FELLA::buildGraphFromKEGGREST(organism = kegg_org_id)
FELLA::buildDataFromGraph(
  keggdata.graph = graph, databaseDir = tmpdir, internalDir = FALSE, matrices = c("hypergeom", "diffusion"),
  normality = c("diffusion"),
  niter = 50
)
FELLAdata <- FELLA::loadKEGGdata(databaseDir = tmpdir, internalDir = FALSE, loadMatrix = "diffusion")

metabolites_kegg_enrichment <- generate_kegg_pathway_enrichment(group = metabolites_kegg_ids)

save_fella_plots(metabolites_kegg_enrichment = metabolites_kegg_enrichment)
save_rds(object = metabolites_kegg_enrichment, filename = "pathway_FELLA_enrichment.rds")
