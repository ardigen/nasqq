include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process FEATURES_PROCESSING {
    tag "${project}"

    input:
        tuple(val(project), val(batch), path(normalized_metabolites))
        val(metadata_column)
        val(zeronan_threshold)
    output:
        tuple(val(project), val(batch), path('results/tables/metabolites_processed.parquet'), emit: fd)
        path('*')

    script:
    """
    chmod 777 -R .
    mkdir -p fontconfig_cache
    export FONTCONFIG_PATH=fontconfig_cache
    mkdir -p .config/matplotlib
    export MPLCONFIGDIR=.config/matplotlib
    mkdir -p results

    features_processing.py \
        --data_file "${normalized_metabolites}" \
        --disease_metacol "${metadata_column}" \
        --batch_metacol "batch" \
        --patient_metacol "patient_no" \
        --zeronan_threshold "${zeronan_threshold}"
    """
}
