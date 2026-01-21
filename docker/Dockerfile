FROM python:3.13-slim

LABEL org.opencontainers.image.source="https://github.com/sohmandal/nf-classpose"
LABEL org.opencontainers.image.description="Classpose WSI cell classification"
LABEL org.opencontainers.image.licenses="MIT"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openslide-tools \
    libopenslide0 \
    libgl1-mesa-glx \
    libglib2.0-0 \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Clone and install classpose
WORKDIR /opt
RUN git clone https://github.com/sohmandal/classpose.git
WORKDIR /opt/classpose
RUN uv sync --frozen

# Pre-download all models
ENV CLASSPOSE_MODEL_DIR=/root/.classpose_models
RUN mkdir -p $CLASSPOSE_MODEL_DIR && \
    uv run python -c "from huggingface_hub import hf_hub_download; \
    [hf_hub_download('classpose/classpose', f'{m}.pt', local_dir='$CLASSPOSE_MODEL_DIR') \
    for m in ['conic', 'consep', 'glysac', 'monusac', 'nucls', 'puma']]"

# Set PATH to include venv
ENV PATH="/opt/classpose/.venv/bin:$PATH"

# Default working directory
WORKDIR /data

ENTRYPOINT []
