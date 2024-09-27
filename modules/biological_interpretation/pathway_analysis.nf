include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process PATHWAY_ANALYSIS {
    tag "${project}"
    label "process_medium"
    container "ghcr.io/ardigen/nasqq/r_utils"
    publishDir "${params.outDir}/${project}/pathway_analysis/${type}", mode: 'copy'

    input:
        tuple(val(project), val(type), path(input_path))
        val(top_n)
        val(kegg_org_id)
    output:
        path("*"), emit: whole_output

    script:
    """
    pathway_analysis.R \
        --input_file_path "${input_path}" \
        --top_n "${top_n}" \
        --kegg_org_id "${kegg_org_id}"
    """
}
