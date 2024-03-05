include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process GROUP_DELAY_CORRECTION {
    tag "${project}"
    label "process_low"

    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range), path(fd))
    output:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range), path(fd),path('results/tables/*_grouped_FIDdata_GDC.rds'), emit: flow)
        path("results/*")

    script:
    """
    group_delay_corection.R --id "${project}" --raw_rds "${fd}"
    """
}
