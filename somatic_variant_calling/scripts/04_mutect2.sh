#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

GATK_IMAGE="broadinstitute/gatk:4.6.2.0"
mkdir -p "$REPO_ROOT/tmp"
log_docker_digest "$GATK_IMAGE"

log_run "mutect2" "docker run --rm --cpus=16 --memory=32g \
  --log-driver=none \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT/tmp':/tmp \
  -e TMPDIR=/tmp \
  -e _JAVA_OPTIONS='-Djava.io.tmpdir=/tmp' \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk --java-options '-Xmx24g -Djava.io.tmpdir=/tmp' Mutect2 \
    --tmp-dir /tmp \
    -R ref/GRCh38_no_alt.fasta \
    -I results/align/tumor.markdup.bam \
    -I results/align/normal.markdup.bam \
    -tumor HCC1395 \
    -normal HCC1395BL \
    -O results/hcc1395.somatic.raw.vcf.gz"
