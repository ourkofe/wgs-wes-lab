#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

BWA_IMAGE="staphb/bwa:latest"
SAMTOOLS_IMAGE="staphb/samtools:latest"
mkdir -p "$REPO_ROOT/results/align"
mkdir -p "$REPO_ROOT/tmp"
log_docker_digest "$BWA_IMAGE"
log_docker_digest "$SAMTOOLS_IMAGE"

declare -A SAMPLES=(
  [tumor]="SRR7890824:HCC1395"
  [normal]="SRR7890827:HCC1395BL"
)

for label in "${!SAMPLES[@]}"; do
  IFS=':' read -r prefix sm <<< "${SAMPLES[$label]}"

  log_run "bwa_mem_${label}" "docker run --rm --cpus=16 --memory=24g \
    --log-driver=none \
    --user $(id -u):$(id -g) \
    -v '$REPO_ROOT/tmp':/tmp \
    -e TMPDIR=/tmp \
    -v '$REPO_ROOT':/work -w /work \
    $BWA_IMAGE \
    bwa mem -t 16 -R '@RG\tID:${prefix}\tSM:${sm}\tPL:ILLUMINA\tLB:lib1' \
      ref/GRCh38_no_alt.fasta \
      data/${prefix}_1.fastq.gz data/${prefix}_2.fastq.gz \
    | docker run -i --rm --cpus=8 --memory=12g \
      --log-driver=none \
      --user $(id -u):$(id -g) \
      -v '$REPO_ROOT/tmp':/tmp \
      -e TMPDIR=/tmp \
      -v '$REPO_ROOT':/work -w /work \
      $SAMTOOLS_IMAGE \
      samtools sort -T /tmp/${label}_sort -@ 8 -o results/align/${label}.sorted.bam -"

  log_run "index_${label}" "docker run --rm --log-driver=none --user $(id -u):$(id -g) \
    -v '$REPO_ROOT':/work -w /work \
    $SAMTOOLS_IMAGE \
    samtools index results/align/${label}.sorted.bam"

  if [ ! -s "$REPO_ROOT/results/align/${label}.sorted.bam.bai" ]; then
    echo "ERROR: ${label} 인덱스 파일 생성 실패"
    exit 1
  fi
done

du -sh "$REPO_ROOT/results/align"
