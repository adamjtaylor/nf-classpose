process CLASSPOSE_PREDICT_WSI {
    tag "$meta.id"
    label 'process_gpu'

    input:
    tuple val(meta), path(slide), path(roi)

    output:
    tuple val(meta), path("${meta.id}_cell_contours.geojson"), emit: contours
    tuple val(meta), path("${meta.id}_cell_centroids.geojson"), emit: centroids
    tuple val(meta), path("${meta.id}_tissue_mask.geojson"), emit: tissue, optional: true
    tuple val(meta), path("${meta.id}_artefact_mask.geojson"), emit: artefact, optional: true
    tuple val(meta), path("${meta.id}_cells.csv"), emit: csv, optional: true
    tuple val(meta), path("${meta.id}.zarr"), emit: spatialdata, optional: true
    path "versions.yml", emit: versions

    script:
    // Determine model config (per-sample override or global default)
    def model_config = meta.model_config ?: params.model_config

    // Build optional arguments
    def args = []

    // ROI
    if (roi) {
        args << "--roi-geojson ${roi}"
    }

    // Tissue detection
    if (params.tissue_detection_model_path) {
        args << "--tissue-detection-model-path ${params.tissue_detection_model_path}"
    }

    // Artefact detection
    if (params.artefact_detection_model_path) {
        args << "--artefact-detection-model-path ${params.artefact_detection_model_path}"
    }

    // Filter artefacts
    if (params.filter_artefacts) {
        args << "--filter-artefacts"
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

    // Output type
    if (params.output_type) {
        args << "--output-type ${params.output_type}"
    }

    def args_str = args.join(' ')

    """
    classpose predict-wsi \\
        --slide-path ${slide} \\
        --model-config ${model_config} \\
        --output-prefix ${meta.id} \\
        --batch-size ${params.batch_size} \\
        --tile-size ${params.tile_size} \\
        --overlap ${params.overlap} \\
        ${args_str}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        classpose: \$(classpose --version 2>&1 | sed 's/classpose //g' || echo "unknown")
    END_VERSIONS
    """
}
