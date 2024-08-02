include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process BATCH_CORRECTION {
    tag "${project}"

    input:
        tuple(val(project), val(batch), path(normalized_metabolites))
        val(metadata_column)
    output:
        tuple(val(project), val(batch), path('metabolites_batch_corrected.txt'), emit: flow)
        val(metadata_column)

    script:
    """
    chmod 777 -R .
    mkdir -p fontconfig_cache
    export FONTCONFIG_PATH=fontconfig_cache
    mkdir -p .config/matplotlib
    export MPLCONFIGDIR=.config/matplotlib
    mkdir -p results

    batch_correction.py \
        --data_file "${normalized_metabolites}" \
        --disease_metacol "${metadata_column}" \
        --batch_metacol "batch" \
        --patient_metacol "patient_no"
    """
}
