#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

GATK_IMAGE="broadinstitute/gatk:4.6.2.0"
log_docker_digest "$GATK_IMAGE"

# SNP만 따로 추출
log_run "select_snps" "docker run --rm --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk SelectVariants -R ref/GRCh38_no_alt.fasta -V results/HG002_chr20.raw.vcf.gz \
    --select-type-to-include SNP -O results/HG002_chr20.snps.vcf.gz"

# indel만 따로 추출
log_run "select_indels" "docker run --rm --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk SelectVariants -R ref/GRCh38_no_alt.fasta -V results/HG002_chr20.raw.vcf.gz \
    --select-type-to-include INDEL -O results/HG002_chr20.indels.vcf.gz"

# SNP hard filter (GATK 공식 권장 기준)
log_run "filter_snps" "docker run --rm --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk VariantFiltration -R ref/GRCh38_no_alt.fasta -V results/HG002_chr20.snps.vcf.gz \
    --filter-expression 'QD < 2.0' --filter-name 'QD2' \
    --filter-expression 'FS > 60.0' --filter-name 'FS60' \
    --filter-expression 'MQ < 40.0' --filter-name 'MQ40' \
    --filter-expression 'MQRankSum < -12.5' --filter-name 'MQRankSum-12.5' \
    --filter-expression 'ReadPosRankSum < -8.0' --filter-name 'ReadPosRankSum-8' \
    --filter-expression 'SOR > 3.0' --filter-name 'SOR3' \
    -O results/HG002_chr20.snps.filtered.vcf.gz"

# indel hard filter (GATK 공식 권장 기준)
log_run "filter_indels" "docker run --rm --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk VariantFiltration -R ref/GRCh38_no_alt.fasta -V results/HG002_chr20.indels.vcf.gz \
    --filter-expression 'QD < 2.0' --filter-name 'QD2' \
    --filter-expression 'FS > 200.0' --filter-name 'FS200' \
    --filter-expression 'ReadPosRankSum < -20.0' --filter-name 'ReadPosRankSum-20' \
    --filter-expression 'SOR > 10.0' --filter-name 'SOR10' \
    -O results/HG002_chr20.indels.filtered.vcf.gz"

# 다시 합치기
log_run "merge_filtered" "docker run --rm --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk MergeVcfs -I results/HG002_chr20.snps.filtered.vcf.gz -I results/HG002_chr20.indels.filtered.vcf.gz \
    -O results/HG002_chr20.final.vcf.gz"
