#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

mkdir -p "$REPO_ROOT/data"
cd "$REPO_ROOT/data"

RUNS="ERR2000715 ERR2000716 ERR2000718 ERR2000720 ERR2000722"

declare -A RUN_PATH=(
  [ERR2000715]="ERR200/005/ERR2000715"
  [ERR2000716]="ERR200/006/ERR2000716"
  [ERR2000718]="ERR200/008/ERR2000718"
  [ERR2000720]="ERR200/000/ERR2000720"
  [ERR2000722]="ERR200/002/ERR2000722"
)

for run in $RUNS; do
  path="${RUN_PATH[$run]}"
  log_run "download_${run}" \
    "wget -c https://ftp.sra.ebi.ac.uk/vol1/fastq/${path}/${run}.fastq.gz"
done

du -sh "$REPO_ROOT/data"
