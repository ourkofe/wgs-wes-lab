#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

mkdir -p "$REPO_ROOT/ref/truth"
cd "$REPO_ROOT/ref/truth"

BASE_URL="https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/seqc/Somatic_Mutation_WG/release/latest"

log_run "download_snv_truth" \
  "wget -c ${BASE_URL}/high-confidence_sSNV_in_HC_regions_v1.2.1.vcf.gz"
log_run "download_indel_truth" \
  "wget -c ${BASE_URL}/high-confidence_sINDEL_in_HC_regions_v1.2.1.vcf.gz"
log_run "download_hc_bed" \
  "wget -c ${BASE_URL}/High-Confidence_Regions_v1.2.bed"

du -sh "$REPO_ROOT/ref/truth"
