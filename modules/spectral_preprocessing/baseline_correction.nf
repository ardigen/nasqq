include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process BASELINE_CORRECTION {
    tag "${project}"
    label "process_medium"
    
    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(window_selection_range), path(fd), path(input_path))
    output:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(window_selection_range), path(fd),path('results/tables/*_grouped_Spectrum_data_BC.rds'), emit: flow)
        path("results/*")

    script:
    """
    baseline_correction.R --id "${project}" --spectra_ir "${input_path}" --raw_rds "${fd}"
    """
}
