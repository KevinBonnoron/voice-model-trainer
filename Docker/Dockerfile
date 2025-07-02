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
    espeak-ng \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

### Stage 2: Build ############################################################
FROM deps AS builder

WORKDIR /workspace

RUN git clone --depth 1 https://github.com/rhasspy/piper.git piper && \
    cd ./piper/src/python && \
    pip install --no-cache-dir -e . \
    && ./build_monotonic_align.sh \
    && cd /workspace \
    && rm -rf piper/.git

### Stage 3: Runtime ##########################################################
FROM python:3.10-slim

WORKDIR /workspace

RUN useradd -m -u 1000 python && \
    mkdir -m 777 /tmp/numba_cache && \
    mkdir -m 777 /tmp/mplconfigdir

USER python

# Copy Python packages and piper
COPY --from=builder /usr/local/lib/python3.10/site-packages/ /usr/local/lib/python3.10/site-packages/
COPY --from=builder /workspace/piper /workspace/piper

# Copy scripts
COPY --chmod=755 scripts/*.py ./
