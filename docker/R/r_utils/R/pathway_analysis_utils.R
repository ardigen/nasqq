#!/usr/bin/env Rscript

suppressMessages({
  library(optparse)
  library(FELLA)
  library(dplyr)
  library(visNetwork)
  library(igraph)
})

#' Convert an igraph object to a visNetwork object
#'
#' This function converts an igraph object to a visNetwork object for visualization.
#'
#' @param g An igraph object.
#' @return A visNetwork object suitable for visualization.
#' @export
#' @importFrom visNetwork visNetwork visIgraphLayout visEdges visOptions
igraph_to_visnetwork <- function(g) {
  V_g <- V(g)
  id <- V_g$name
  label <- V_g$label

  if ("GO.simil" %in% list.vertex.attributes(g)) {
    GO.simil <- unlist(V_g$GO.simil)
    GO.annot <- TRUE
  } else {
    GO.annot <- FALSE
  }

  map.com <- c("pathway", "module", "enzyme", "reaction", "compound")
  map.color <- c("#E6A3A3", "#E2D3E2", "#DFC1A3", "#D0E5F2", "#A4D4A4")
  map.labelcolor <- c("#CD0000", "#CD96CD", "#CE6700", "#8DB6CD", "#548B54")
  map.nodeWidth <- c(40, 30, 25, 22, 22)

  nodeShape <- ifelse(V_g$input, "box", "ellipse")
  nodes <- data.frame(id, label, stringsAsFactors = FALSE) %>%
    dplyr::mutate(group = map.com[V_g$com], color = map.color[V_g$com], value = map.nodeWidth[V_g$com], shape = nodeShape)

  if (GO.annot) {
    ids <- !is.na(GO.simil)
    GO.semsim <- GO.simil[ids]
    GO.hits <- names(GO.semsim)
    if (!is.null(GO.hits)) {
      newColor <- sapply(
        GO.semsim, function(x) {
          if (x < 0.5) {
            return("#FFD500")
          } else if (x < 0.7) {
            return("#FF5500")
          } else if (x < 0.9) {
            return("#FF0000")
          }
          return("#B300FF")
        }
      )
      newName <- paste0(nodes$label[ids], "[", GO.hits, "]")
      newShape <- "triangle"

      # modify name and color
      nodes$label[ids] <- newName
      nodes$color[ids] <- newColor
      nodes$shape[ids] <- newShape
    }
  }

  nodeLink <- paste0("<a href=\"http://www.genome.jp/dbget-bin/www_bget?", V_g$name, "\"", " target=\"_blank", "\">", V_g$name, "</a>")
  if (vcount(g) ==
    0) {
    nodeLink <- character(0)
  }

  nodes$title <- nodeLink

  source <- V_g[get.edgelist(g)[
    ,
    1
  ]]$name
  target <- V_g[get.edgelist(g)[
    ,
    2
  ]]$name
  edges <- data.frame(source, target, stringsAsFactors = FALSE)

  names(edges) <- c("from", "to")

  net <- list(nodes = nodes, edges = edges)

  visNetwork::visNetwork(nodes = net$nodes, edges = net$edges) %>%
    visNetwork::visIgraphLayout() %>%
    visNetwork::visEdges(smooth = FALSE) %>%
    visNetwork::visOptions(selectedBy = "group", nodesIdSelection = TRUE, highlightNearest = TRUE)
}

#' List of metabolite names along with their KEGG IDs
#' 
#' This list provides the names of metabolites along with their corresponding KEGG IDs for reference and analysis purposes.
#' @name metabolite_kegg_ids_dict
#' @usage metabolite_kegg_ids_dict
no_kegg_id <- "NO_KEGG_ID"

metabolite_kegg_ids_dict <- c(
  "1,3-Diaminopropane" = "C00986",
  "Levoglucosan" = "C22350",
  "1-Methylhydantoin" = "C02565",
  "1-Methyl-L-Histidine" = "C01152",
  "QuinolinicAcid" = "C03722",
  "2-AminoAdipicAcid" = "C00956",
  "2-AminobutyricAcid" = "C02261",
  "2-Deoxyadenosine" = "C00559",
  "2-Deoxycytidine" = "C00881",
  "2-Deoxyguanosine" = "C00330",
  "dAMP" = "C00360",
  "2-Oxoisovalerate" = "C00141",
  "2-HydroxybutyricAcid" = "C05984",
  "2-HydroxyphenylAceticAcid" = "C05852",
  "2-MethylglutaricAcid" = no_kegg_id,
  "2-Oxobutyrate" = "C00109",
  "2-Oxoglutarate" = "C00026",
  "2-PicolinicAcid" = "C10164",
  "2-Propanol" = "C01845",
  "3-Hydroxybutyrate" = "C01089",
  "3-HydroxyphenylAceticAcid" = "C05593",
  "3-MethyladipicAcid" = no_kegg_id,
  "3-Methyl-L-Histidine" = "C01152",
  "3-Methylxanthine" = "C16357",
  "3-PhenylPropionicAcid" = "C05629",
  "4-AminoHippuricAcid" = no_kegg_id,
  "4-EthylPhenol" = "C13637",
  "4-HydroxyphenylAceticAcid" = "C00642",
  "Dihydrothymine" = "C00906",
  "5-AminoValericAcid" = "C00431",
  "7-Methylxanthine" = "C16353",
  "Acetaminophen" = "C06804",
  "AceticAcid" = "C00033",
  "Acetoacetate" = "C00164",
  "Acetone" = "C00207",
  "Adenine" = "C00147",
  "Adenosine" = "C00212",
  "AdipicAcid" = "C06104",
  "ADP" = "C00008",
  "Allantoin" = "C01551",
  "alpha-HydroxyisobutyricAcid" = "C05984",
  "AMP" = "C00020",
  "ArgininosuccinicAcid" = "C03406",
  "AscorbicAcid" = "C00072",
  "ATP" = "C00002",
  "Azelaic Acid" = "C08261",
  "BenzoicAcid" = "C00180",
  "Beta-Alanine" = "C00099",
  "beta-HydroxyisovalericAcid" = "C20827",
  "Betaine" = "C00719",
  "Butyrate" = "C00246",
  "Cadaverine" = "C01672",
  "CDP" = "C00112",
  "CholineChloride" = no_kegg_id,
  "CitraconicAcid" = "C02226",
  "Citrate" = "C00158",
  "CMP" = "C00055",
  "Creatine" = "C00300",
  "Creatinine" = "C00791",
  "CTP" = "C00063",
  "Cytosine" = "C00380",
  "DehydroAscorbicAcid" = "C05422",
  "D-Fructose" = "C00095",
  "D-Fucose" = "C01018",
  "D-Galactose" = "C00124",
  "D-GluconicAcid" = "C00257",
  "D-Glucose" = "C00031",
  "D-Glucose-6-Phosphate" = "C00092",
  "D-GlucuronicAcid" = "C16245",
  "Dimethylamine" = "C00543",
  "Dimethylglycine" = "C01026",
  "Dimethylsulfone" = "C11142",
  "D-Maltose" = "C00208",
  "D-Mannose" = "C00159",
  "D-Sorbitol" = "C00794",
  "Ethanolamine" = "C00189",
  "EthylmalonicAcid" = no_kegg_id,
  "Formate" = "C00058",
  "FumaricAcid" = "C00122",
  "GABA" = "C00334",
  "Galactitol" = "C01697",
  "GDP" = "C00035",
  "GlutaconicAcid" = "C02214",
  "GlutaricAcid" = "C00489",
  "GlycericAcid" = "C00258",
  "Glycerol" = "C00116",
  "Glycerophosphocholine" = "C00670",
  "Glycogen" = "C00182",
  "GlycolicAcid" = "C00160",
  "GlyoxylicAcid" = "C00048",
  "GMP" = "C00144",
  "GTP" = "C00044",
  "GuanidinoaceticAcid" = "C00581",
  "HippuricAcid" = "C01586",
  "HomovanillicAcid" = "C05582",
  "Hypotaurine" = "C00519",
  "Hypoxanthine" = "C00262",
  "IMP" = "C00130",
  "Indoxylsulfate" = no_kegg_id,
  "Inosine" = "C00294",
  "Isobutyrate" = "C02632",
  "IsocitricAcid" = "C00311",
  "IsovalericAcid" = "C08262",
  "KynurenicAcid" = "C01717",
  "Lactate" = "C01432",
  "Lactose" = "C00243",
  "L-Alanine" = "C00041",
  "L-Anserine" = "C01262",
  "L-Arabitol" = "C00532",
  "L-Arginine" = "C00062",
  "L-Asparagine" = "C00152",
  "L-Aspartate" = "C00049",
  "L-Carnitine" = "C00318",
  "L-Carnosine" = "C00386",
  "L-Citrulline" = "C00327",
  "L-Cysteine" = "C00097",
  "L-Cystine" = "C00491",
  "LevulinicAcid" = no_kegg_id,
  "L-GlutamicAcid" = "C00025",
  "L-Glutamine" = "C00064",
  "L-Glutathione-oxidized" = no_kegg_id,
  "L-Glutathione-reduced" = "C00051",
  "L-Glycine" = "C00037",
  "L-Histidine" = "C00135",
  "L-Isoleucine" = "C00407",
  "L-Leucine" = "C00123",
  "L-Lysine" = "C00047",
  "L-Methionine" = "C00073",
  "L-Ornithine" = "C00077",
  "L-Phenylalanine" = "C00079",
  "L-Proline" = "C00148",
  "L-Serine" = "C00065",
  "L-Threonine" = "C00188",
  "L-Tryptophane" = "C00078",
  "L-Tyrosine" = "C00082",
  "L-Valine" = "C00183",
  "MalicAcid" = "C00149",
  "Malonate" = "C00383",
  "MandelicAcid" = "C01983",
  "Methanol" = "C00132",
  "Methylamine" = "C00218",
  "Methylguanidine" = "C02294",
  "MethylmalonicAcid" = "C02170",
  "Myo-Inositol" = "C00137",
  "N-(2-Furoyl)Glycine" = no_kegg_id,
  "N-Acetylglycine" = no_kegg_id,
  "N-Acetyl-L-AsparticAcid" = "C01042",
  "NAD" = "C00003",
  "NADP" = "C00006",
  "NicotinicAcid" = "C00253",
  "NicotinuricAcid" = "C05380",
  "O-Acetyl-L-Carnitine" = "C02571",
  "Oxypurinol" = "C07599",
  "PantothenicAcid" = "C00864",
  "Phenethylamine" = "C05332",
  "PhenylglyoxylicAcid" = "C02137",
  "Phosphocholine" = "C00588",
  "PimelicAcid" = "C02656",
  "Propionate" = "C00163",
  "PropyleneGlycol" = "C00583",
  "Pyrocatechol" = "C00090",
  "PyroglutamicAcid" = "C01879",
  "Pyruvic-Acid" = "C00022",
  "SaccaricAcid" = "C00818",
  "S-Acetamidomethylcysteine" = no_kegg_id,
  "Sarcosine" = "C00213",
  "SebacicAcid" = "C08277",
  "Spermidine" = "C00315",
  "Succinate" = "C00042",
  "SyringicAcid" = "C10833",
  "TartaricAcid" = "C00898",
  "Taurine" = "C00245",
  "Threitol" = "C16884",
  "ThreonicAcid" = "C01620",
  "TMAO" = "C01104",
  "trans-4-Hydroxy-L-Proline" = "C01157",
  "Trans-AcotinicAcid" = "C02341",
  "trans-FerulicAcid" = "C01494",
  "Trigonelline" = "C01004",
  "Trimethylamine" = "C00565",
  "UDP" = "C00015",
  "UDPG" = "C00029",
  "UMP" = "C00105",
  "Uracil" = "C00106",
  "Uridine" = "C00299",
  "UrocanicAcid" = "C00785",
  "UTP" = "C00075",
  "Valerate" = "C00803",
  "VanillicAcid" = "C06672",
  "Xylitol" = "C00379",
  "Putrescine" = "C00134"
)

#' Translate ASICS metabolite names to KEGG IDs
#'
#' This function translates ASICS metabolite names to their corresponding KEGG IDs using a provided dictionary.
#'
#' @param metabo_list A character vector of ASICS metabolite names.
#' @param met_dict A named character vector containing ASICS metabolite names as names and their corresponding KEGG IDs as values. Defaults to \code{metabolite_kegg_ids_dict}.
#' @return A character vector of KEGG IDs corresponding to the input ASICS metabolite names.
#' @export

translate_ASICS_to_KEGG_ids <- function(metabo_list, met_dict = metabolite_kegg_ids_dict) {
  metabo_list %>%
    dplyr::recode(., !!!met_dict) %>%
    setdiff(., no_kegg_id)
}

#' Generate KEGG pathway enrichment analysis
#'
#' This function performs KEGG pathway enrichment analysis for a given group of metabolites using the FELLA package.
#'
#' @param group A character vector containing the names of metabolites for which enrichment analysis will be performed.
#' @param enrich_approx A character specifying the approximation method used for enrichment analysis. Defaults to "normality".
#' @param results_table_method A character specifying the method used for generating results table. Defaults to "diffusion".
#' @param results_graph_method A character specifying the method used for generating the results graph. Defaults to "diffusion".
#' @param vertex.label.cex A numeric value specifying the label size for vertices in the results graph. Defaults to 0.5.
#' @param nlimit An integer specifying the maximum number of nodes in the results graph. Defaults to 250.
#' @return A list containing the defined compounds, enriched compounds, results table, and visual representation of the results graph.
#' @export
generate_kegg_pathway_enrichment <- function(group, enrich_approx = "normality", results_table_method = "diffusion", results_graph_method = "diffusion", vertex.label.cex = 0.5,
                                             nlimit = 250) {
  defined_compounds <- FELLA::defineCompounds(compounds = group, data = FELLAdata)
  enriched_compounds <- FELLA::enrich(
    compounds = FELLA::getInput(defined_compounds),
    data = FELLAdata, method = FELLA::listMethods(), approx = enrich_approx
  )
  results_table <- FELLA::generateResultsTable(object = enriched_compounds, data = FELLAdata, method = results_table_method)
  g_plot <- FELLA::generateResultsGraph(object = enriched_compounds, data = FELLAdata, method = results_graph_method, nlimit = nlimit)
  g_plot_vis <- igraph_to_visnetwork(g_plot)
  list(
    defined_compounds = defined_compounds, enriched_compounds = enriched_compounds, results_table = results_table, g_plot = g_plot,
    g_plot_vis = g_plot_vis
  )
}

#' Save FELLA plots
#'
#' This function saves FELLA plots generated during KEGG pathway enrichment analysis.
#'
#' @param metabolites_kegg_enrichment A list containing the results of KEGG pathway enrichment analysis.
#' @param directory A character string specifying the directory where the plots will be saved. Defaults to "results/figures".
#' @param nlimit An integer specifying the maximum number of nodes in the results graph. Defaults to 250.
#' @param plot_size A numeric vector specifying the width and height of the plot in inches. Defaults to c(12, 8).
#' @param show_legend A logical value indicating whether to include a legend in the plot. Defaults to TRUE.
#' @param plot_method A character specifying the method used for generating the plot. Defaults to "diffusion".
#' @return NULL
#' @export
save_fella_plots <- function(metabolites_kegg_enrichment, directory = "results/figures", nlimit = 250, plot_size = c(12, 8),
                             show_legend = TRUE, plot_method = "diffusion") {
  dir.create(directory, showWarnings = FALSE, recursive = TRUE)
  htmltools::save_html(html = metabolites_kegg_enrichment$g_plot_vis, file = file.path(directory, "metabolites_kegg_enrichment.html"))
  png(file = file.path(directory, "metabolites_kegg_enrichment.png"),
    width = plot_size[1]*900, height = plot_size[2]*900, res = 900
  )
  FELLA::plot(
    metabolites_kegg_enrichment$enriched_compounds,
    method = plot_method, data = FELLAdata, nlimit = nlimit, vertex.label.cex = 1e-15,
    plotLegend = show_legend, edge.length = 10
  )
  dev.off()
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
