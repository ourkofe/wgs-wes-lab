#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

HAPPY_IMAGE="pkrusche/hap.py:latest"
mkdir -p "$REPO_ROOT/results/happy"
log_docker_digest "$HAPPY_IMAGE"

log_run "happy_validation" "docker run --rm --cpus=8 --memory=16g \
  --user $(id -u):$(id -g) \
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/group:/etc/group:ro \
  -v '$REPO_ROOT':/work -w /work \
  $HAPPY_IMAGE \
  /opt/hap.py/bin/hap.py \
    ref/truth/HG002_truth.vcf.gz \
    results/HG002_chr20.final.vcf.gz \
    -f ref/truth/HG002_truth_regions.bed \
    -r ref/GRCh38_no_alt.fasta \
    -o results/happy/HG002_chr20 \
    -l chr20 \
    --threads 8"
