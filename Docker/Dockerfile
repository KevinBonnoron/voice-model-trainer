### Stage 1: Dependencies #####################################################
FROM python:3.10-slim AS deps

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-dev \
    git \
    gcc \
    g++ \
    make \
    cmake \
    ninja-build \
    espeak-ng \
    sox \
    libsox-fmt-all \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY Docker/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

### Stage 2: Build ############################################################
FROM deps AS builder

WORKDIR /workspace

# Install piper non-editable so espeakbridge lands in site-packages.
# The wheel does not include piper.train.vits (only piper.train), so we copy
# the full vits package from source and add the built monotonic_align .so.
RUN git clone --depth 1 https://github.com/OHF-Voice/piper1-gpl.git piper && \
    cd ./piper && \
    pip install --no-cache-dir '.[train]' \
    && ./build_monotonic_align.sh \
    && cp -r src/piper/train/vits /usr/local/lib/python3.10/site-packages/piper/train/ \
    && cp -r src/piper/train/vits/monotonic_align/monotonic_align/* \
       /usr/local/lib/python3.10/site-packages/piper/train/vits/monotonic_align/ \
    && cd /workspace \
    && rm -rf piper

### Stage 3: Runtime ##########################################################
FROM python:3.10-slim

WORKDIR /workspace

RUN apt-get update && apt-get install -y --no-install-recommends \
    espeak-ng \
    sox \
    libsox-fmt-all \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -u 1000 python \
    && mkdir -m 777 /tmp/numba_cache \
    && mkdir -m 777 /tmp/mplconfigdir

USER python

# Only site-packages: piper is installed there with espeakbridge and monotonic_align
COPY --from=builder /usr/local/lib/python3.10/site-packages/ /usr/local/lib/python3.10/site-packages/
# Scripts for export (e.g. write Piper ONNX config from checkpoint)
COPY Docker/scripts/ /workspace/scripts/
