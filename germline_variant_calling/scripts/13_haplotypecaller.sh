#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

GATK_IMAGE="broadinstitute/gatk:4.6.2.0"
log_docker_digest "$GATK_IMAGE"

log_run "haplotypecaller" "docker run --rm --cpus=16 --memory=32g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk --java-options '-Xmx24g' HaplotypeCaller \
    -R ref/GRCh38_no_alt.fasta \
    -I results/align/HG002_chr20.recal.bam \
    -L chr20 \
    -O results/HG002_chr20.raw.vcf.gz"
