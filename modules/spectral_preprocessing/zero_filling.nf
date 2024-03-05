include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process ZERO_FILLING {
    tag "${project}"
    label "process_low"

    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range), path(fd), path(input_path))
    output:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range), path(fd),path('results/tables/*_grouped_FIDdata_ZF.rds'), emit: flow)
        path("results/*")

    script:
    """
    zero_filling.R --id "${project}" --fid_a "${input_path}" --raw_rds "${fd}"
    """
}
