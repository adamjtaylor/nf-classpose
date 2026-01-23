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

include { VIPS_CONVERT } from './modules/local/vips_convert'
include { CLASSPOSE_PREDICT_WSI } from './modules/local/classpose_predict_wsi'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Check required parameters
if (!params.input) {
    error "ERROR: Please provide an input samplesheet with --input"
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    HELPER FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Check if a file needs conversion (OME-TIFF formats not natively supported by OpenSlide)
def needsConversion(path) {
    def name = path.toString().toLowerCase()
    return name.endsWith('.ome.tif') || name.endsWith('.ome.tiff')
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

            def slide = file(row.slide_path, checkIfExists: true)

            // Auto-derive sample_id from filename (without extensions)
            def meta = [
                id: slide.simpleName
            ]

            return [meta, slide]
        }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {
    // Parse samplesheet
    ch_samples = parseSamplesheet(params.input)

    // Branch based on format compatibility
    ch_samples
        .branch {
            convert: needsConversion(it[1])
            passthrough: true
        }
        .set { ch_branched }

    // Convert OME-TIFF files to OpenSlide-compatible format
    ch_converted = VIPS_CONVERT(ch_branched.convert)

    // Combine converted files with passthrough files
    ch_ready = ch_branched.passthrough.mix(ch_converted.slide)

    // Run classpose prediction
    CLASSPOSE_PREDICT_WSI(ch_ready)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    log.info ""
    log.info "Pipeline completed at: ${workflow.complete}"
    log.info "Execution status: ${workflow.success ? 'OK' : 'failed'}"
    log.info "Results published to: ${params.outdir}"
    log.info ""
}
