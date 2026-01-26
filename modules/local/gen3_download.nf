process GEN3_DOWNLOAD {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), val(drs_uri)
    path credentials

    output:
    tuple val(meta), path("*.{svs,ndpi,tiff,tif,mrxs,scn,bif,vms,vmu}"), emit: slide
    path "versions.yml", emit: versions

    script:
    // Validate gen3_profile contains only safe characters (alphanumeric, hyphens, underscores)
    if (!params.gen3_profile.matches(/^[a-zA-Z0-9_-]+$/)) {
        error "Invalid gen3_profile: '${params.gen3_profile}'. Profile names must contain only alphanumeric characters, hyphens, and underscores."
    }

    // Validate gen3_api_endpoint is a valid HTTPS URL
    if (!params.gen3_api_endpoint.matches(/^https:\/\/[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9](\/[a-zA-Z0-9._\/-]*)?$/)) {
        error "Invalid gen3_api_endpoint: '${params.gen3_api_endpoint}'. Must be a valid HTTPS URL."
    }

    // Extract GUID from DRS URI: drs://nci-crdc.datacommons.io/dg.4DFC/guid -> dg.4DFC/guid
    def guid = drs_uri.toString().replaceFirst(/^drs:\/\/[^\/]+\//, '')

    // Validate GUID contains only safe characters (alphanumeric, dots, hyphens, underscores, slashes)
    if (!guid.matches(/^[a-zA-Z0-9._\/-]+$/)) {
        error "Invalid GUID format: '${guid}'. GUIDs must contain only alphanumeric characters, dots, hyphens, underscores, and slashes."
    }
    """
    # Set HOME for gen3-client config (needed when running as non-root user)
    export HOME=\$PWD

    # Configure gen3-client profile
    gen3-client configure \\
        --profile="${params.gen3_profile}" \\
        --cred="${credentials}" \\
        --apiendpoint="${params.gen3_api_endpoint}"

    # Download file using GUID
    gen3-client download-single \\
        --profile="${params.gen3_profile}" \\
        --guid="${guid}" \\
        --download-path=. \\
        --no-prompt \\
        --skip-completed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gen3-client: \$(gen3-client --version 2>&1 | head -1 || echo "unknown")
    END_VERSIONS
    """

    stub:
    """
    touch "${meta.id}.ome.tiff"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gen3-client: stub
    END_VERSIONS
    """
}
