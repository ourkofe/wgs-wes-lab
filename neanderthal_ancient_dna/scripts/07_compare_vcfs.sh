#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

GATK_IMAGE="broadinstitute/gatk:4.6.2.0"
log_docker_digest "$GATK_IMAGE"

# HG002 최종 VCF를 이쪽 폴더로 복사 (컨테이너 마운트 범위 안에 있어야 함)
cp ../germline_variant_calling/results/HG002_chr20.final.vcf.gz ref/
cp ../germline_variant_calling/results/HG002_chr20.final.vcf.gz.tbi ref/

log_run "select_concordant" "docker run --rm --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk SelectVariants -R ref/GRCh38_no_alt.fasta \
    -V results/vindija_chr20.raw.vcf.gz \
    --concordance ref/HG002_chr20.final.vcf.gz \
    -O results/vindija_concordant_with_hg002.vcf.gz"

log_run "select_discordant" "docker run --rm --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk SelectVariants -R ref/GRCh38_no_alt.fasta \
    -V results/vindija_chr20.raw.vcf.gz \
    --discordance ref/HG002_chr20.final.vcf.gz \
    -O results/vindija_only.vcf.gz"
