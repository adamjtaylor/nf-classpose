# nf-classpose

Nextflow pipeline wrapper for [Classpose](https://github.com/sohmandal/classpose) WSI cell classification.

## Features

- CSV samplesheet input for batch processing
- Pre-built Docker container with all 6 models included
- Support for Docker, Singularity, and Apptainer
- GPU acceleration support
- Per-sample model configuration

## Quick Start

```bash
# Run with Docker
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    -profile docker

# Run with GPU support
nextflow run main.nf \
    --input samplesheet.csv \
    --outdir results \
    -profile docker,gpu
```

## Installation

### Requirements

- [Nextflow](https://www.nextflow.io/) (>=23.04.0)
- [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/singularity/) or [Apptainer](https://apptainer.org/)

### Container

The pipeline uses a pre-built container with all dependencies and models:

```
ghcr.io/sohmandal/nf-classpose:latest
```

## Samplesheet Format

Create a CSV file with the following columns:

```csv
sample_id,slide_path,roi_geojson,model_config
sample1,/data/slide1.svs,,
sample2,/data/slide2.tiff,/data/roi2.geojson,
sample3,/data/slide3.ndpi,,consep
```

| Column | Required | Description |
|--------|----------|-------------|
| `sample_id` | Yes | Unique identifier for the sample |
| `slide_path` | Yes | Path to WSI file (.svs, .tiff, .ndpi, etc.) |
| `roi_geojson` | No | Optional ROI GeoJSON file |
| `model_config` | No | Per-sample model override |

## Parameters

### Input/Output

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--input` | required | Path to samplesheet CSV |
| `--outdir` | `results` | Output directory |

### Model Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--model_config` | `conic` | Default model: conic, consep, glysac, monusac, nucls, puma |

### Tissue/Artefact Detection

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--tissue_detection_model_path` | null | Path to GrandQC tissue model |
| `--artefact_detection_model_path` | null | Path to GrandQC artefact model |
| `--filter_artefacts` | false | Filter cells in artefact regions |

### Inference Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--batch_size` | 8 | Inference batch size |
| `--device` | null | Device (cuda:0, mps, cpu) |
| `--bf16` | false | Use bfloat16 inference |
| `--tta` | false | Enable test-time augmentation |

### Tiling Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--tile_size` | 1024 | Tile size in pixels |
| `--overlap` | 64 | Tile overlap in pixels |

### Output Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--output_type` | null | Additional outputs: csv, spatialdata |

## Profiles

| Profile | Description |
|---------|-------------|
| `docker` | Run with Docker |
| `singularity` | Run with Singularity |
| `apptainer` | Run with Apptainer |
| `gpu` | Enable GPU support (combine with container profile) |
| `test` | Run with test configuration |

### Examples

```bash
# Basic run with Docker
nextflow run main.nf --input samples.csv -profile docker

# GPU-accelerated run
nextflow run main.nf --input samples.csv -profile docker,gpu

# Singularity with custom model
nextflow run main.nf \
    --input samples.csv \
    --model_config consep \
    -profile singularity,gpu

# Test profile
nextflow run main.nf -profile test,docker
```

## Outputs

The pipeline produces the following outputs for each sample:

| File | Description |
|------|-------------|
| `{sample_id}_cell_contours.geojson` | Cell contour polygons |
| `{sample_id}_cell_centroids.geojson` | Cell centroid points |
| `{sample_id}_tissue_mask.geojson` | Tissue mask (if tissue detection enabled) |
| `{sample_id}_artefact_mask.geojson` | Artefact mask (if artefact detection enabled) |
| `{sample_id}_cells.csv` | Cell data table (if --output_type csv) |
| `{sample_id}.zarr` | SpatialData object (if --output_type spatialdata) |

## Building the Container Locally

```bash
# Build Docker image
docker build -t nf-classpose docker/

# Verify models are present
docker run nf-classpose ls /root/.classpose_models
```

## License

MIT
