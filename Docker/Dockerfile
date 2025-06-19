FROM python:3.10

WORKDIR /workspace
ARG UID=1000
ARG GID=1000

RUN apt-get update && apt-get install -y \
    python3-dev \
    espeak-ng \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/rhasspy/piper.git piper && \
    cd ./piper/src/python && \
    pip install \
        "numpy<2" \
        torchmetrics==0.11.4 \
        onnxsim \
        --upgrade wheel setuptools \
        -e . \
    && ./build_monotonic_align.sh

COPY --chmod=700 ./pre-process.sh ./pre-process.sh
COPY --chmod=700 ./train.sh ./train.sh
COPY --chmod=700 ./generate-test-sentences.sh ./generate-test-sentences.sh
COPY --chmod=700 ./export.sh ./export.sh

RUN groupadd -g "${GID}" python \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" python

RUN chown -R python /workspace
USER python
