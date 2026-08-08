#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

GATK_IMAGE="broadinstitute/gatk:4.6.2.0"
mkdir -p "$REPO_ROOT/tmp"
log_docker_digest "$GATK_IMAGE"

log_run "filter_mutect_calls" "docker run --rm --cpus=8 --memory=16g \
  --log-driver=none \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT/tmp':/tmp \
  -e TMPDIR=/tmp \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk --java-options '-Xmx12g -Djava.io.tmpdir=/tmp' FilterMutectCalls \
    --tmp-dir /tmp \
    -R ref/GRCh38_no_alt.fasta \
    -V results/hcc1395.somatic.raw.vcf.gz \
    -O results/hcc1395.somatic.filtered.vcf.gz"
