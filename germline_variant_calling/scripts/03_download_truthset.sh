#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

mkdir -p "$REPO_ROOT/ref/truth"
cd "$REPO_ROOT/ref/truth"

BASE_URL="https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/AshkenazimTrio/HG002_NA24385_son/NISTv4.2.1/GRCh38"

log_run "download_truth_vcf" "wget -O HG002_truth.vcf.gz ${BASE_URL}/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz"
log_run "download_truth_bed" "wget -O HG002_truth_regions.bed ${BASE_URL}/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed"

du -sh "$REPO_ROOT/ref/truth"
