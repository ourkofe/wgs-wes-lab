#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

GATK_IMAGE="broadinstitute/gatk:4.6.2.0"
SAMTOOLS_IMAGE="staphb/samtools:latest"
log_docker_digest "$GATK_IMAGE"

log_run "mark_duplicates" "docker run --rm --cpus=8 --memory=32g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk --java-options '-Xmx24g' MarkDuplicates \
    -I results/align/HG002_chr20.sorted.bam \
    -O results/align/HG002_chr20.markdup.bam \
    -M results/align/HG002_chr20.markdup.metrics.txt"

log_run "index_markdup_bam" "docker run --rm --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $SAMTOOLS_IMAGE \
  samtools index results/align/HG002_chr20.markdup.bam"
