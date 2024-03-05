include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process FOURIER_TRANSFORMATION {
    tag "${project}"
    label "process_medium"

    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range), path(fd), path(input_path))
    output:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range), path(fd),path('results/tables/*_grouped_RawSpect_data_FT.rds'), emit: flow)
        path("results/*")

    script:
    """
    fourier_transformation.R --id "${project}" --fid_zf "${input_path}"  --raw_rds "${fd}"
    """
}
