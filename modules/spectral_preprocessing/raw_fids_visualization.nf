include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process RAW_FIDS_VISUALIZATION {
    tag "${project}"
    label "process_medium"
    
    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range), path(fd))
    output:
        path('results/*'), emit: raw_plots_out

    script:
    """
    raw_fids_visualization.R --id "${project}" --raw_rds "${fd}"
    """
}
