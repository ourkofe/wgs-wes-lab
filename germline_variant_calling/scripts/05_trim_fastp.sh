#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

FASTP_IMAGE="quay.io/biocontainers/fastp:0.23.4--h5f740d0_0"
mkdir -p "$REPO_ROOT/data/trimmed" "$REPO_ROOT/results/qc/fastp"
log_docker_digest "$FASTP_IMAGE"

log_run "fastp" "docker run --rm --cpus=8 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $FASTP_IMAGE \
  fastp -i data/HG002_chr20_R1.fastq.gz -I data/HG002_chr20_R2.fastq.gz \
        -o data/trimmed/HG002_chr20_R1.trimmed.fastq.gz \
        -O data/trimmed/HG002_chr20_R2.trimmed.fastq.gz \
        -h results/qc/fastp/fastp.html -j results/qc/fastp/fastp.json"
