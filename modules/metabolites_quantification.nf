include { initOptions } from './functions'

params.options = [:]
options    = initOptions(params.options)

process METABOLITES_QUANTIFICATION {
    tag "${project}"
    label "process_high"
    container "ghcr.io/ardigen/nasqq/r_utils"
    publishDir "${params.outDir}/${project}/metabolites_quantification/", mode: 'copy'

    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), path(fd), path(input_path))
        val(ncores)
        val(quantif_method)
    output:
        tuple(val(project), val(batch), path(metadata_file), path("*_quantified_metabolites.txt"), emit: flow)
        path("*"), emit: output

    script:
    """
    metabolites_quantification.R \
        --id "${project}" \
        --dir-path "." \
        --peps-format-file "normalized_metabolites.txt" \
        --ncores ${ncores} \
        --quantif-method ${quantif_method}
    """
}
