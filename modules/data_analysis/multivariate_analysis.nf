include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process MULTIVARIATE_ANALYSIS {
    tag "${project}"
    label "process_high"

    input:
        tuple(val(project), val(batch), path(normalized_metabolites))
        val(metadata_column)
        val(test_size)
        val(cross_val_fold)
    output:
        tuple(val(project),val("multivariate"), path("results/tables/*features_relative_importance.csv"), emit: multivariate)
        path("results/tables/models_stratification.csv")
        tuple(path("results/figures/*weights.svg"), path("results/tables/*features_weights.csv"), emit: optional_output, optional: true)

    script:
    """
    chmod 777 -R .
    mkdir -p fontconfig_cache
    export FONTCONFIG_PATH=fontconfig_cache
    mkdir -p .config/matplotlib
    export MPLCONFIGDIR=.config/matplotlib
    mkdir -p results

    multivariate_analysis.py \
        --data_file "${normalized_metabolites}" \
        --disease_metacol "${metadata_column}" \
        --patient_metacol "patient_no" \
        --batch_metacol "batch" \
        --test_size "${test_size}" \
        --cross_val_fold "${cross_val_fold}"
    """
}
