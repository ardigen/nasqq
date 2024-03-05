# Biological Interpretation

Script designed for biological interpretation of metabolites from the 1D 1H NMR Experiments.

## I - Pathway Analysis

`pathway_analysis.R` script performs pathway enrichment analysis using the FELLA package.

```bash
./pathway_enrichment_analysis.R --input_file_path <Input File Path> --top_n <Top N> --kegg_org_id <KEGG Organism ID>
```

### Options

* `--input_file_path`:  Path to the input file from the multi/univariate module.
* `--top_n`: Number of metabolites to include in enrichment (default: `20`).
* `--kegg_org_id`: KEGG organism ID (default: `"hsa"`).

### Output

The script generates the following outputs:

* `pathway_FELLA_enrichment.rds`: RDS file containing FELLA pathway enrichment results.
* `metabolites_kegg_enrichment.html`: HTML plot which allows exploration of the enriched KEGG pathways interactively.
* `metabolites_kegg_enrichment.pdf`: PDF static plot of the enriched KEGG pathways.

## Usage

### Prerequisites

Install the required R packages by running:

```bash
Rscript -e 'install.packages(c("BiocManager", "dplyr", "ggplot2", "DT", "visNetwork", "igraph", "svglite", "optparse"))'
Rscript -e 'BiocManager::install("FELLA")'
```

### Running scripts

Navigate to your working directory and execute the realpath of the script's location with proper parameters by running the aforementioned command.

Apart from main workflow script, supplementary `pathway_analysis_utils.R` script contains a collection of utility functions that serve different purposes in the biological interpretation, pathway enrichment and visualisation of static/ interactive KEGG-based pathways.

Additional Notes:
* Adjust paths and filenames in the command based on your project structure.
* Ensure required dependencies (libcairo2-dev etc.) are installed and `pathway_analysis_utils.R` is available in the same location as all utilized script, as it contains the crucial functions for analysis.
* (Ideally) Run all scripts in provided R_utils docker container.
* Script's input should be consistent wit Data Analysis module output.
* Main functions originate from exisiting package [FELLA](https://www.bioconductor.org/packages/release/bioc/html/FELLA.html).

#### License

This project is licensed under the custom License - see the [LICENSE.md](../LICENSE.md) file for details.
