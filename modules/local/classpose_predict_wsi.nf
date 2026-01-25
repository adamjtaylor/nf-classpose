process CLASSPOSE_PREDICT_WSI {
    tag "$meta.id-$model"
    label 'process_gpu'
    publishDir "${params.outdir}/${meta.id}/${model}", mode: 'copy'

    input:
    tuple val(meta), path(slide), val(model)

    output:
    tuple val(meta), path("${meta.id}_cell_contours.geojson"), emit: contours
    tuple val(meta), path("${meta.id}_cell_centroids.geojson"), emit: centroids
    tuple val(meta), path("${meta.id}_tissue_contours.geojson"), emit: tissue, optional: true
    tuple val(meta), path("${meta.id}_artefact_contours.geojson"), emit: artefact, optional: true
    tuple val(meta), path("${meta.id}_cell_densities.csv"), emit: csv, optional: true
    tuple val(meta), path("${meta.id}_spatialdata.zarr"), emit: spatialdata, optional: true
    path "versions.yml", emit: versions

    script:
    // Build optional arguments
    def args = []

    // ROI
    if (params.roi_geojson) {
        args << "--roi_geojson ${params.roi_geojson}"
    }

    // Tissue detection
    if (params.tissue_detection_model_path) {
        args << "--tissue_detection_model_path ${params.tissue_detection_model_path}"
    }

    // Artefact detection (only run if filter_artefacts is enabled)
    if (params.filter_artefacts && params.artefact_detection_model_path) {
        args << "--artefact_detection_model_path ${params.artefact_detection_model_path}"
        args << "--filter_artefacts"
    }

    // Device
    if (params.device) {
        args << "--device ${params.device}"
    }

    // Precision
    if (params.bf16) {
        args << "--bf16"
    }

    // Test-time augmentation
    if (params.tta) {
        args << "--tta"
    }

    // Output type (nargs="+" expects space-separated values without quotes)
    if (params.output_type) {
        args << "--output_type ${params.output_type}"
    }

    def args_str = args.join(' ')

    """
    classpose-predict-wsi \\
        --slide_path ${slide} \\
        --model_config ${model} \\
        --output_folder . \\
        --batch_size ${params.batch_size} \\
        --tile_size ${params.tile_size} \\
        --overlap ${params.overlap} \\
        ${args_str}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        classpose: \$(classpose-predict-wsi --help 2>&1 | head -1 || echo "unknown")
    END_VERSIONS
    """
}
