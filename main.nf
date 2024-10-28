#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

def modules = params.modules.clone()
params.options = [:]

include { isFileEmpty } from './modules/functions'

include { PARSE_SAMPLES                 } from './subworkflows/parser'
include { SPECTRAL_PREPROCESSING        } from './subworkflows/spectral_preprocessing'
include { METABOLITES_QUANTIFICATION    } from './modules/metabolites_quantification'
include { ADD_METADATA                  } from './modules/data_analysis/add_metadata'
include { COMBINE_DATASET_BATCHES       } from './modules/data_analysis/combine_dataset_batches'
include { BATCH_CORRECTION              } from './modules/data_analysis/batch_correction'
include { DATA_ANALYSIS                 } from './subworkflows/data_analysis'
include { PATHWAY_ANALYSIS as PATHWAY_ANALYSIS_UNIVARIATE } from './modules/biological_interpretation/pathway_analysis'
include { PATHWAY_ANALYSIS as PATHWAY_ANALYSIS_MULTIVARIATE } from './modules/biological_interpretation/pathway_analysis'


workflow {

    log.info("""\

            .--:--:---.\\
          {}  : {}   :                           __  _  __   __  ____
          ||__\"_||   :                          |  || ||  \\ /  || __ \\
         /        \\  `={}_                      | N \\ A| S   Q || Q_| \\
        |   NASQQ  |  (   )                     |_| \\_||_| V |_||_| \\_|
        |  v1.0.0  |  (   )                     
        |    ____  |  (   )    Nextflow Automatization and Standarization for Qualitative and Quantitative
        |   |    | |  (   )             1H 1D NMR metabolomics data preparation and analysis
        |___|____|_|  (   )                   =======================================
        |          |  (   )                   input from     : ${params.manifest}
       /|    ||    |\\ (   )                   output to      : ${params.outDir}
      | |    ||    | |(   )                   ------
      | |____||____| |(   )                   run as         : ${workflow.commandLine}
      |   _________  |(   )                   started at     : ${workflow.start}
      |  |   | |   | |(   )                   launchdir at   : ${workflow.projectDir}
      |__|   |_|   |_|(___)
      
      """)

    PARSE_SAMPLES(params.manifest)
    SPECTRAL_PREPROCESSING(PARSE_SAMPLES.out.samples)
    METABOLITES_QUANTIFICATION(SPECTRAL_PREPROCESSING.out.normalized_metabolites, params.ncores, params.quantif_method)
    ADD_METADATA(METABOLITES_QUANTIFICATION.out.flow, params.log1p, params.metadata_column)

    if (params.run_combine_project_batches) {
        combinedResults_to_merge = ADD_METADATA.out.files_to_merge.collect()
        combinedResults_without_merge = ADD_METADATA.out.files_without_merge.collect()
        if (combinedResults_to_merge) {
            COMBINE_DATASET_BATCHES(combinedResults_to_merge)
            merged_input = COMBINE_DATASET_BATCHES.out
            
            if (params.run_batch_correction) {
                BATCH_CORRECTION(merged_input, params.metadata_column)
                corrected_data = BATCH_CORRECTION.out.flow
            } else {
                corrected_data = merged_input
            }
        }
        if (combinedResults_without_merge){
            not_merged_input = combinedResults_without_merge}

        input_data_analysis = corrected_data.mix(not_merged_input)

    } else {
        input_data_analysis = ADD_METADATA.out.flow
    }

    DATA_ANALYSIS(input_data_analysis, params.metadata_column)
    
    DATA_ANALYSIS.out.multivariate
        .filter { multivariateData -> 
            def (project, type, multivariateFile) = multivariateData
            return !isFileEmpty(project, multivariateFile)
        }
        .set { validMultivariateData }

    PATHWAY_ANALYSIS_MULTIVARIATE(validMultivariateData, params.top_n, params.kegg_org_id)
    PATHWAY_ANALYSIS_UNIVARIATE(DATA_ANALYSIS.out.univariate, params.top_n, params.kegg_org_id)
}

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
