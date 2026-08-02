#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

MAPDAMAGE_IMAGE="quay.io/biocontainers/mapdamage2:2.2.3--py312h4711d71_0"
mkdir -p "$REPO_ROOT/results/mapdamage"
log_docker_digest "$MAPDAMAGE_IMAGE"

RUNS="ERR2000715 ERR2000716 ERR2000718 ERR2000720 ERR2000722"

for run in $RUNS; do
  log_run "mapdamage_${run}" "docker run --rm --cpus=4 --memory=8g \
    --user $(id -u):$(id -g) \
    -v '$REPO_ROOT':/work -w /work \
    $MAPDAMAGE_IMAGE \
    mapDamage -i results/align/${run}.sorted.bam -r ref/GRCh38_no_alt.fasta \
      -d results/mapdamage/${run} --no-stats"
done
