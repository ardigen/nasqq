include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process EXPLORATORY_DATA_ANALYSIS {
    tag "${project}"
    label "process_low"

    input:
        tuple(val(project), val(batch), path(normalized_metabolites))
        val(metadata_column)
    output:
        path('*'), emit: fd

    script:
    """
    chmod 777 -R .
    mkdir -p fontconfig_cache
    export FONTCONFIG_PATH=fontconfig_cache
    mkdir -p .config/matplotlib
    export MPLCONFIGDIR=.config/matplotlib
    mkdir -p results

    if [ "${batch}" == 'None' ]; then
        exploratory_data_analysis.py \
            --data_file "${normalized_metabolites}" \
            --disease_metacol "${metadata_column}" \
            --patient_metacol "patient_no"
    else
        exploratory_data_analysis.py \
            --data_file "${normalized_metabolites}" \
            --disease_metacol "${metadata_column}" \
            --patient_metacol "patient_no" \
            --batch_metacol "batch"
    fi
    """
}
