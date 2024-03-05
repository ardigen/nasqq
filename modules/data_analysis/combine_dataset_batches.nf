include { initOptions } from '../functions'

params.options = [:]
options    = initOptions(params.options)

process COMBINE_DATASET_BATCHES {
    input:
        path(input_path)
    output:
        tuple(val("combined_projects"), val("combined_projects_batch"), path("merged_batches.txt"), emit: flow)

    script:
    """
    merge_batches.py --folder_path "." --output_name merged_batches.txt
    """
}
