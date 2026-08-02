#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

GATK_IMAGE="broadinstitute/gatk:4.6.2.0"
log_docker_digest "$GATK_IMAGE"

RUNS="ERR2000715 ERR2000716 ERR2000718 ERR2000720 ERR2000722"

for run in $RUNS; do
  log_run "markdup_${run}" "docker run --rm --cpus=8 --memory=16g \
    --user $(id -u):$(id -g) \
    -v '$REPO_ROOT':/work -w /work \
    $GATK_IMAGE \
    gatk --java-options '-Xmx12g' MarkDuplicates \
      -I results/align/${run}.sorted.bam \
      -O results/align/${run}.markdup.bam \
      -M results/align/${run}.markdup.metrics.txt \
      --VALIDATION_STRINGENCY LENIENT"

  log_run "index_markdup_${run}" "docker run --rm --user $(id -u):$(id -g) \
    -v '$REPO_ROOT':/work -w /work \
    staphb/samtools:latest \
    samtools index results/align/${run}.markdup.bam"
done
