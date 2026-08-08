#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

mkdir -p "$REPO_ROOT/data"
cd "$REPO_ROOT/data"

# 종양 (HCC1395)
log_run "download_tumor_r1" \
  "wget -c https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR789/004/SRR7890824/SRR7890824_1.fastq.gz"
log_run "download_tumor_r2" \
  "wget -c https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR789/004/SRR7890824/SRR7890824_2.fastq.gz"

# 정상 (HCC1395BL)
log_run "download_normal_r1" \
  "wget -c https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR789/007/SRR7890827/SRR7890827_1.fastq.gz"
log_run "download_normal_r2" \
  "wget -c https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR789/007/SRR7890827/SRR7890827_2.fastq.gz"

du -sh "$REPO_ROOT/data"
