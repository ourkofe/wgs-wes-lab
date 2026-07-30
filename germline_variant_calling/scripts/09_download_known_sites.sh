#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

mkdir -p "$REPO_ROOT/ref/known_sites"

BASE_S3="s3://broad-references/hg38/v0"

log_run "download_dbsnp" \
  "aws s3 cp --no-sign-request ${BASE_S3}/Homo_sapiens_assembly38.dbsnp138.vcf '$REPO_ROOT/ref/known_sites/'"
log_run "download_dbsnp_idx" \
  "aws s3 cp --no-sign-request ${BASE_S3}/Homo_sapiens_assembly38.dbsnp138.vcf.idx '$REPO_ROOT/ref/known_sites/'"
log_run "download_mills" \
  "aws s3 cp --no-sign-request ${BASE_S3}/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz '$REPO_ROOT/ref/known_sites/'"
log_run "download_mills_tbi" \
  "aws s3 cp --no-sign-request ${BASE_S3}/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi '$REPO_ROOT/ref/known_sites/'"

du -sh "$REPO_ROOT/ref/known_sites"
