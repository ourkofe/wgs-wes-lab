#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

GATK_IMAGE="broadinstitute/gatk:4.6.2.0"
log_docker_digest "$GATK_IMAGE"

log_run "base_recalibrator" "docker run --rm --cpus=8 --memory=32g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk --java-options '-Xmx24g' BaseRecalibrator \
    -R ref/GRCh38_no_alt.fasta \
    -I results/align/HG002_chr20.markdup.bam \
    --known-sites ref/known_sites/Homo_sapiens_assembly38.dbsnp138.vcf \
    --known-sites ref/known_sites/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \
    -O results/align/HG002_chr20.recal_data.table"

log_run "apply_bqsr" "docker run --rm --cpus=8 --memory=32g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk --java-options '-Xmx24g' ApplyBQSR \
    -R ref/GRCh38_no_alt.fasta \
    -I results/align/HG002_chr20.markdup.bam \
    --bqsr-recal-file results/align/HG002_chr20.recal_data.table \
    -O results/align/HG002_chr20.recal.bam"
