FROM python:3.13-slim

LABEL org.opencontainers.image.source="https://github.com/adamjtaylor/nf-classpose"
LABEL org.opencontainers.image.description="Classpose WSI cell classification"
LABEL org.opencontainers.image.licenses="MIT"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openslide-tools \
    libopenslide0 \
    libgl1 \
    libglib2.0-0 \
    git \
    curl \
    unzip \
    procps \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Clone and install classpose
WORKDIR /opt
RUN git clone https://github.com/sohmandal/classpose.git
WORKDIR /opt/classpose
RUN uv sync

# Pre-download classpose models (conic and consep bundled)
# See: https://github.com/adamjtaylor/nf-classpose/issues/3 for adding more models
ENV CLASSPOSE_MODEL_DIR=/root/.classpose_models
RUN mkdir -p $CLASSPOSE_MODEL_DIR && \
    uv run python -c "from huggingface_hub import hf_hub_download; \
    hf_hub_download('classpose/classpose', 'conic.pt', local_dir='$CLASSPOSE_MODEL_DIR'); \
    hf_hub_download('classpose/classpose', 'consep.pt', local_dir='$CLASSPOSE_MODEL_DIR')"

# Pre-download GrandQC models for tissue/artefact detection
ENV GRANDQC_MODEL_DIR=/root/.grandqc_models
RUN mkdir -p $GRANDQC_MODEL_DIR/tissue $GRANDQC_MODEL_DIR/artefact && \
    # Tissue detection model from Zenodo
    curl -L "https://zenodo.org/records/14507273/files/Tissue_Detection_MPP10.pth?download=1" \
        -o $GRANDQC_MODEL_DIR/tissue/Tissue_Detection_MPP10.pth && \
    # Artefact detection models from Zenodo
    curl -L "https://zenodo.org/records/14041538/files/GrandQC_MPP15.pth?download=1" \
        -o $GRANDQC_MODEL_DIR/artefact/GrandQC_MPP15.pth

# Pre-download EfficientNet backbone weights used by GrandQC
RUN mkdir -p /root/.cache/torch/hub/checkpoints && \
    curl -L "https://github.com/rwightman/pytorch-image-models/releases/download/v0.1-weights/tf_efficientnet_b0_aa-827b6e33.pth" \
        -o /root/.cache/torch/hub/checkpoints/tf_efficientnet_b0_aa-827b6e33.pth

# Set PATH to include venv
ENV PATH="/opt/classpose/.venv/bin:$PATH"

# Default working directory
WORKDIR /data

ENTRYPOINT []
