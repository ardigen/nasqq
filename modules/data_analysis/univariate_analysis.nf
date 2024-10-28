include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process UNIVARIATE_ANALYSIS {
    tag "${project}"

    input:
        tuple(val(project), val(batch), path(normalized_metabolites))
        val(metadata_column)
        val(pvalue_shapiro)
    output:
        tuple(val(project), val("univariate"), path("results/tables/univariate_analysis.csv"), emit: univariate)
        path("results/outliers.txt")

    script:
    """
    chmod 777 -R .
    mkdir -p fontconfig_cache
    export FONTCONFIG_PATH=fontconfig_cache
    mkdir -p .config/matplotlib
    export MPLCONFIGDIR=.config/matplotlib
    mkdir -p results/tables

    univariate_analysis.py \
        --data_file "${normalized_metabolites}" \
        --disease_metacol "${metadata_column}" \
        --patient_metacol "patient_no" \
        --pvalue_shapiro ${pvalue_shapiro}
    """
}
