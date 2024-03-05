include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process LOAD_FIDS {
    tag "${project}"
    label "process_low"

    input:
        tuple(val(project), val(batch), path(input_path), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range))
        val(check_pulse_samples)
    output:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range), path('results/tables/*_selected_fid_list.rds'), emit:flow)
        path('results/tables/*')

    script:
    """
    load_fids.R --id "${project}" --raw_data_path "${input_path}" --pulse_program "${check_pulse_samples}" --selected_sample_names "${selected_sample_names}"
    """
}
