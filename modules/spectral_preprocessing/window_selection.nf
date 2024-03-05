include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process WINDOW_SELECTION {
    tag "${project}"
    label "process_low"

    input:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), val(window_selection_range), path(fd), path(input_path))
    output:
        tuple(val(project), val(batch), val(selected_sample_names), path(metadata_file), path(fd),path('results/tables/*_grouped_Spectrum_data_WS.rds'), emit: flow)
        path("results/*")

    script:
    """
    from_ws=`echo "$window_selection_range" | cut -d ';' -f2`
    to_ws=`echo "$window_selection_range" | cut -d ';' -f1`
    window_selection.R --id "${project}" --spectra_nvz "${input_path}" --from_ws "\$from_ws" --to_ws "\$to_ws"
    """
}
