process VIPS_CONVERT {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(image)

    output:
    tuple val(meta), path("${meta.id}.tif"), emit: slide

    script:
    def compression = params.vips_compression ?: 'jpeg'
    """
    vips tiffsave "${image}" "${meta.id}.tif" \\
        --compression=${compression} \\
        --Q=90 \\
        --tile \\
        --tile-width=256 \\
        --tile-height=256 \\
        --pyramid \\
        --bigtiff
    """
}
