#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

GATK_IMAGE="broadinstitute/gatk:4.6.2.0"
HC_BED="ref/truth/High-Confidence_Regions_v1.2.bed"
mkdir -p "$REPO_ROOT/tmp" "$REPO_ROOT/results/compare"
log_docker_digest "$GATK_IMAGE"

log_run "select_snps_hc" "docker run --rm --log-driver=none --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT/tmp':/tmp -e TMPDIR=/tmp \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk SelectVariants -R ref/GRCh38_no_alt.fasta \
    -V results/hcc1395.somatic.filtered.vcf.gz \
    -L $HC_BED \
    --select-type-to-include SNP \
    --exclude-filtered \
    -O results/compare/hcc1395.snps.pass.hc.vcf.gz"

log_run "select_indels_hc" "docker run --rm --log-driver=none --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT/tmp':/tmp -e TMPDIR=/tmp \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk SelectVariants -R ref/GRCh38_no_alt.fasta \
    -V results/hcc1395.somatic.filtered.vcf.gz \
    -L $HC_BED \
    --select-type-to-include INDEL \
    --exclude-filtered \
    -O results/compare/hcc1395.indels.pass.hc.vcf.gz"

log_run "snp_concordant_hc" "docker run --rm --log-driver=none --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT/tmp':/tmp -e TMPDIR=/tmp \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk SelectVariants -R ref/GRCh38_no_alt.fasta \
    -V results/compare/hcc1395.snps.pass.hc.vcf.gz \
    --concordance ref/truth/high-confidence_sSNV_in_HC_regions_v1.2.1.vcf.gz \
    -O results/compare/snp_concordant.hc.vcf.gz"

log_run "snp_discordant_hc" "docker run --rm --log-driver=none --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT/tmp':/tmp -e TMPDIR=/tmp \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk SelectVariants -R ref/GRCh38_no_alt.fasta \
    -V results/compare/hcc1395.snps.pass.hc.vcf.gz \
    --discordance ref/truth/high-confidence_sSNV_in_HC_regions_v1.2.1.vcf.gz \
    -O results/compare/snp_discordant.hc.vcf.gz"

log_run "indel_concordant_hc" "docker run --rm --log-driver=none --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT/tmp':/tmp -e TMPDIR=/tmp \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk SelectVariants -R ref/GRCh38_no_alt.fasta \
    -V results/compare/hcc1395.indels.pass.hc.vcf.gz \
    --concordance ref/truth/high-confidence_sINDEL_in_HC_regions_v1.2.1.vcf.gz \
    -O results/compare/indel_concordant.hc.vcf.gz"

log_run "indel_discordant_hc" "docker run --rm --log-driver=none --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT/tmp':/tmp -e TMPDIR=/tmp \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk SelectVariants -R ref/GRCh38_no_alt.fasta \
    -V results/compare/hcc1395.indels.pass.hc.vcf.gz \
    --discordance ref/truth/high-confidence_sINDEL_in_HC_regions_v1.2.1.vcf.gz \
    -O results/compare/indel_discordant.hc.vcf.gz"
