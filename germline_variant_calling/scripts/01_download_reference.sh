#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

mkdir -p "$REPO_ROOT/ref"
cd "$REPO_ROOT/ref"

# GIAB가 권장하는 GRCh38 레퍼런스 (ALT contig 없는 버전 - GIAB 정답셋이 이 기준으로 만들어짐)
log_run "download_reference" \
  "wget -O GRCh38_no_alt.fasta.gz https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta.gz"

log_run "unzip_reference" "gunzip -k GRCh38_no_alt.fasta.gz"

du -sh "$REPO_ROOT/ref"
