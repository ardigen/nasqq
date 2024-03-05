include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process NEGATIVE_VALUES_ZEROING {
    tag "${project}"
    label "process_low"

    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(window_selection_range), path(fd), path(input_path))

    output:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(window_selection_range), path(fd),path('results/tables/*_grouped_Spectrum_data_NVZ.rds'), emit: flow)
        path("results/*")

    script:
    """
    negative_values_zeroing.R --id "${project}" --spectra_bc "${input_path}" --raw_rds "${fd}"
    """
}
