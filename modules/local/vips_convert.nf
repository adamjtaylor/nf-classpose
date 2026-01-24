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
    # Extract PhysicalSizeX from OME-XML and convert to pixels/mm for VIPS
    # OME stores PhysicalSizeX in micrometers, VIPS needs pixels/mm
    # Formula: pixels_per_mm = 1000 / physical_size_um

    PHYSICAL_SIZE=\$(vipsheader -f image-description "${image}" 2>/dev/null | grep -oP 'PhysicalSizeX="\\K[0-9.]+' | head -1)

    if [ -n "\$PHYSICAL_SIZE" ]; then
        # Convert micrometers to pixels/mm: 1000 / mpp
        PIXELS_PER_MM=\$(awk "BEGIN {printf \\"%.6f\\", 1000 / \$PHYSICAL_SIZE}")
        echo "Extracted PhysicalSizeX: \$PHYSICAL_SIZE um/pixel -> \$PIXELS_PER_MM pixels/mm"
        RES_ARGS="--xres=\$PIXELS_PER_MM --yres=\$PIXELS_PER_MM"
    else
        echo "WARNING: Could not extract PhysicalSizeX from OME-XML, resolution metadata will not be set"
        RES_ARGS=""
    fi

    vips tiffsave "${image}" "${meta.id}.tif" \\
        --compression=${compression} \\
        --Q=90 \\
        --tile \\
        --tile-width=256 \\
        --tile-height=256 \\
        --pyramid \\
        --bigtiff \\
        \$RES_ARGS
    """
}
