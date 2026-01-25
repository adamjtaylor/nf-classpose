#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-classpose
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Nextflow wrapper for Classpose WSI cell classification
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CLASSPOSE_PREDICT_WSI } from './modules/local/classpose_predict_wsi'
include { GEN3_DOWNLOAD } from './modules/local/gen3_download'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    HELPER FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Check if a path is a DRS URI
def isDrsUri(path) {
    return path.toString().startsWith('drs://')
}

// Extract sample ID from DRS URI (use GUID as ID)
def drsUriToId(drs_uri) {
    // drs://nci-crdc.datacommons.io/dg.4DFC/624693b0-7e68-11ee-a75b-033941d3e6da
    // Extract the last part of the GUID as ID
    def guid = drs_uri.toString().replaceFirst(/^drs:\/\/[^\/]+\//, '')
    return guid.replaceAll(/[\/.]/, '_')
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PARSE SAMPLESHEET
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def parseSamplesheet(samplesheet) {
    Channel
        .fromPath(samplesheet, checkIfExists: true)
        .splitCsv(header: true, strip: true)
        .map { row ->
            // Validate required fields
            if (!row.slide_path) {
                error "ERROR: Missing slide_path in samplesheet row: ${row}"
            }

            def slide_path = row.slide_path

            // Handle DRS URIs differently - don't check if file exists
            if (isDrsUri(slide_path)) {
                def meta = [
                    id: drsUriToId(slide_path)
                ]
                return [meta, slide_path]
            } else {
                def slide = file(slide_path, checkIfExists: true)
                def meta = [
                    id: slide.baseName
                ]
                return [meta, slide]
            }
        }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {
    // Validate inputs
    if (!params.input) {
        error "ERROR: Please provide an input samplesheet with --input"
    }

    // Parse samplesheet
    ch_input = parseSamplesheet(params.input)

    // Branch based on URI type
    ch_input
        .branch {
            drs: isDrsUri(it[1])
            direct: true
        }
        .set { ch_branched }

    // Validate: fail if DRS URIs present but no credentials
    ch_branched.drs
        .first()
        .subscribe {
            if (!params.gen3_credentials) {
                error "ERROR: DRS URIs found in samplesheet but --gen3_credentials not provided"
            }
        }

    // Download DRS files (only run if credentials provided)
    if (params.gen3_credentials) {
        ch_downloaded = GEN3_DOWNLOAD(
            ch_branched.drs,
            file(params.gen3_credentials)
        )
        // Combine direct paths with downloaded files
        ch_samples = ch_branched.direct.mix(ch_downloaded.slide)
    } else {
        // No credentials, only use direct paths
        ch_samples = ch_branched.direct
    }

    // Run classpose prediction
    CLASSPOSE_PREDICT_WSI(ch_samples)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete = {
    log.info ""
    log.info "Pipeline completed at: ${workflow.complete}"
    log.info "Execution status: ${workflow.success ? 'OK' : 'failed'}"
    log.info "Results published to: ${params.outdir}"
    log.info ""
}
