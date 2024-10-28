include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process BUCKETING {
    tag "${project}"
    label "process_medium"

    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), path(fd), path(input_path))
        val(intmeth)
        val(mb)
    output:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), path(fd),path('results/tables/*_grouped_Spectrum_data_B.rds'), emit: flow)
        path("results/*")

    script:
    """
    bucketing.R --id "${project}" --spectra_ws "${input_path}" --raw_rds "${fd}" --intmeth "${intmeth}" --mb "${mb}"
    """
}
