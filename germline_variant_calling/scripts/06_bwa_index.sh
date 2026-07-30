#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

BWA_IMAGE="staphb/bwa:latest"
SAMTOOLS_IMAGE="staphb/samtools:latest"
log_docker_digest "$BWA_IMAGE"
log_docker_digest "$SAMTOOLS_IMAGE"

log_run "bwa_index" "docker run --rm --cpus=8 --memory=16g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $BWA_IMAGE \
  bwa index ref/GRCh38_no_alt.fasta"

log_run "samtools_faidx" "docker run --rm --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $SAMTOOLS_IMAGE \
  samtools faidx ref/GRCh38_no_alt.fasta"
