# nf-classpose

Nextflow pipeline wrapper for [Classpose](https://github.com/sohmandal/classpose) WSI cell classification.

## Features

- Simple CSV samplesheet input (just slide paths)
- Pre-built Docker container with all 5 models included
- Support for Docker, Singularity, and Apptainer
- GPU acceleration support

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
ghcr.io/adamjtaylor/nf-classpose:latest
```

## Samplesheet Format

Create a CSV file with slide paths:

```csv
slide_path
/data/slide1.svs
/data/slide2.tiff
/data/slide3.ndpi
```

| Column | Required | Description |
|--------|----------|-------------|
| `slide_path` | Yes | Path to WSI file (.svs, .tiff, .ndpi, etc.) |

Sample IDs are automatically derived from the slide filename (e.g., `slide1.svs` → `slide1`).

## Parameters

### Input/Output

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--input` | required | Path to samplesheet CSV |
| `--outdir` | `results` | Output directory |

### Model Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--model_config` | `conic` | Model: conic, consep, glysac, monusac, puma |

### ROI

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--roi_geojson` | null | Path to ROI GeoJSON file (applied to all samples) |

### Tissue/Artefact Detection

GrandQC models are pre-bundled in the container.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--tissue_detection_model_path` | (bundled) | Path to GrandQC tissue model |
| `--artefact_detection_model_path` | (bundled) | Path to GrandQC artefact model |
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
| `--output_type` | `csv spatialdata` | Output formats: csv (density stats), spatialdata (Zarr) |

## Profiles

| Profile | Description |
|---------|-------------|
| `docker` | Run with Docker |
| `singularity` | Run with Singularity |
| `apptainer` | Run with Apptainer |
| `gpu` | Enable GPU support (combine with container profile) |
| `tower` | Resource settings for Seqera Platform (Tower) |
| `tower_gpu` | Tower with GPU acceleration |
| `tower_test` | Test profile for Tower using S3 samplesheet |
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
| `{sample_id}_tissue_contours.geojson` | Tissue contours (if tissue detection enabled) |
| `{sample_id}_artefact_contours.geojson` | Artefact contours (if artefact detection enabled) |
| `{sample_id}_densities.csv` | Cell density statistics (if --output_type csv) |
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
