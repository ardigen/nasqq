include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process NORMALIZATION {
    tag "${project}"
    label "process_medium"

    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), path(fd), path(input_path))
        val(type_norm)
        val(removal_regions)
    output:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file),  path(fd),path('*normalized_metabolites.txt'), emit: flow)
        path("results")

    script:
    """
    normalization.R --id "${project}" --spectra_ws "${input_path}" --raw_rds "${fd}" --type_norm "${type_norm}" --removal_regions "${removal_regions}"
    """
}
