#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

GATK_IMAGE="broadinstitute/gatk:4.6.2.0"
SAMTOOLS_IMAGE="staphb/samtools:latest"
mkdir -p "$REPO_ROOT/tmp"
log_docker_digest "$GATK_IMAGE"

SAMPLES="tumor normal"

for label in $SAMPLES; do
  log_run "markdup_${label}" "docker run --rm --cpus=8 --memory=16g \
    --log-driver=none \
    --user $(id -u):$(id -g) \
    -v '$REPO_ROOT/tmp':/tmp \
    -e TMPDIR=/tmp \
    -v '$REPO_ROOT':/work -w /work \
    $GATK_IMAGE \
    gatk --java-options '-Xmx12g -Djava.io.tmpdir=/tmp' MarkDuplicates \
      -I results/align/${label}.sorted.bam \
      -O results/align/${label}.markdup.bam \
      -M results/align/${label}.markdup.metrics.txt \
      --VALIDATION_STRINGENCY LENIENT"

  log_run "index_markdup_${label}" "docker run --rm --log-driver=none --user $(id -u):$(id -g) \
    -v '$REPO_ROOT':/work -w /work \
    $SAMTOOLS_IMAGE \
    samtools index results/align/${label}.markdup.bam"

  if [ ! -s "$REPO_ROOT/results/align/${label}.markdup.bam.bai" ]; then
    echo "ERROR: ${label} markdup 인덱스 생성 실패"
    exit 1
  fi
done
