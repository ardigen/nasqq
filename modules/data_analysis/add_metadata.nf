include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process ADD_METADATA {
    tag "${project}"

    input:
        tuple(val(project), val(batch), path(disease_state), path(input_path))
        val(log1p)
        val(metadata)
    output:
        tuple(val(project), val(batch), path("*.txt"), emit: flow)
        path("*_merged_file.txt"), emit: files_to_merge , optional: true
        tuple(val(project), val(batch), path("*_merged_file_without_merge.txt"), emit: files_without_merge, optional: true)

    script:
    """
    data_merge.py $input_path $disease_state ${project}_merged_file.txt $batch $log1p $metadata
    """
}
