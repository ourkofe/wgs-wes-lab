#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

GATK_IMAGE="broadinstitute/gatk:4.6.2.0"
log_docker_digest "$GATK_IMAGE"

log_run "haplotypecaller_neanderthal" "docker run --rm --cpus=16 --memory=32g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk --java-options '-Xmx24g' HaplotypeCaller \
    -R ref/GRCh38_no_alt.fasta \
    -I results/align/ERR2000715.markdup.bam \
    -I results/align/ERR2000716.markdup.bam \
    -I results/align/ERR2000718.markdup.bam \
    -I results/align/ERR2000720.markdup.bam \
    -I results/align/ERR2000722.markdup.bam \
    -L chr20 \
    -O results/vindija_chr20.raw.vcf.gz"
