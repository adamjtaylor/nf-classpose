process VIPS_CONVERT {
    tag "$meta.id"
    label 'process_medium'
    container 'ghcr.io/adamjtaylor/nf-classpose:vips-latest'

    input:
    tuple val(meta), path(image)

    output:
    tuple val(meta), path("${meta.id}.*"), emit: converted

    script:
    // Get the file extension
    def filename = image.toString()
    def extension = filename.substring(filename.lastIndexOf('.') + 1)

    // Default compression from params or use 'jpeg'
    def compression = params.vips_compression ?: 'jpeg'

    """
    # Check for OME-TIFF variants or other incompatible formats
    if [[ "${filename}" == *".ome.tif" ]] || [[ "${filename}" == *".ome.tiff" ]]; then
        echo "Converting incompatible format: ${filename}"
        vips tiffsave "${image}" "${meta.id}.tif" \\
            --compression=${compression} \\
            --Q=90 \\
            --tile \\
            --tile-width=256 \\
            --tile-height=256 \\
            --pyramid \\
            --bigtiff
    else
        # Pass-through for compatible formats
        echo "Format compatible, linking file."
        ln -s "${image}" "${meta.id}.${extension}"
    fi
    """
}
