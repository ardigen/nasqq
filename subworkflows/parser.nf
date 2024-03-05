workflow PARSE_SAMPLES {
    take:
        manifestPath
    main:
        manifest = Channel.fromPath(manifestPath, checkIfExists: true).splitCsv(header:true)

        samples = manifest.map{
        [
            it.dataset,
            it.batch,
            file(it.input_path),
            it.selected_sample_names,
            file(it.metadata_file),
            it.target_value,
            it.referencing_range,
            it.window_selection_range
        ]
        }

    emit:
        samples
}
