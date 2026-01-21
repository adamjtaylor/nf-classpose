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
    // Extract GUID from DRS URI: drs://nci-crdc.datacommons.io/dg.4DFC/guid -> dg.4DFC/guid
    def guid = drs_uri.toString().replaceFirst(/^drs:\/\/[^\/]+\//, '')
    """
    # Configure gen3-client profile
    gen3-client configure \\
        --profile=${params.gen3_profile} \\
        --cred=${credentials} \\
        --apiendpoint=${params.gen3_api_endpoint}

    # Download file using GUID
    gen3-client download-single \\
        --profile=${params.gen3_profile} \\
        --guid=${guid} \\
        --download-path=. \\
        --no-prompt \\
        --skip-completed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gen3-client: \$(gen3-client --version 2>&1 | head -1 || echo "unknown")
    END_VERSIONS
    """
}
