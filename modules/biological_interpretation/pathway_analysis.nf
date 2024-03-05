include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process PATHWAY_ANALYSIS {
    tag "${project}"
    label "process_medium"
    publishDir "${params.outDir}/${project}/pathway_analysis/${type}", mode: 'copy'

    input:
        tuple(val(project), val(type), path(input_path))
    output:
        path("*"), emit: whole_output

    script:
    """
    pathway_analysis.R \
        --input_file_path "${input_path}" \
        --top_n "20" \
        --kegg_org_id "hsa"
    """
}
