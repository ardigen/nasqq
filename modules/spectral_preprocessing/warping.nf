include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process WARPING {
    tag "${project}"
    label "process_high"

    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(window_selection_range), path(fd), path(input_path))

    output:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(window_selection_range), path(fd), path('results/tables/*_grouped_Spectrum_data_W.rds'), emit: flow)
        path("results/*")

    script:
    """
    warping.R --id "${project}" --spectra_nvz "${input_path}" --raw_rds "${fd}"
    """
}
