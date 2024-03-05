include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process ZERO_ORDER_PHASE_CORRECTION {
    tag "${project}"
    label "process_medium"

    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range), path(fd), path(input_path))
    output:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range), path(fd), path('results/tables/*_grouped_Spectrum_data_ZOPC*'), emit: flow)
        path("results/*")

    script:
    """
    zero_order_phase_correction.R --id "${project}" --raw_spect_ft "${input_path}" --raw_rds "${fd}"
    """
}
