include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process APODIZATION {
    tag "${project}"
    label "process_low"

    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range), path(fd), path(input_path))
        val(check_pulse_samples)
    output:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range), path(fd),path('results/tables/*_grouped_FIDdata_A.rds'), emit: flow)
        path("results/*")


    script:
    """
    apodization.R --id "${project}" --ss_res "${input_path}" --raw_rds "${fd}" --pulse_prog_value "${check_pulse_samples}"
    """
}
