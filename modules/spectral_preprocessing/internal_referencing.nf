include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process INTERNAL_REFERENCING {
    tag "${project}"
    label "process_medium"
    
    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(target_value), val(referencing_range), val(window_selection_range), path(fd), path(input_path))
        val(reverse_axis_samples)
    output:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(window_selection_range), path(fd),path('results/tables/*_grouped_Spectrum_data_IR.rds'), emit: flow)
        path("results/*")

    script:
    """
    internal_referencing.R --id "${project}" --spectra_zopc "${input_path}" --raw_rds "${fd}" --target_value "${target_value}" --fromto_rc "${referencing_range}" --reverse_axis_samples ${reverse_axis_samples}
    """
}
