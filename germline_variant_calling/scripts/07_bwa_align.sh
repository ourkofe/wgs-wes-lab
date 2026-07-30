#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

BWA_IMAGE="staphb/bwa:latest"
SAMTOOLS_IMAGE="staphb/samtools:latest"
mkdir -p "$REPO_ROOT/results/align"
log_docker_digest "$BWA_IMAGE"

# Read group 정보는 GATK가 필수로 요구함 (샘플 식별용 메타데이터)
RG="@RG\tID:HG002\tSM:HG002\tPL:ILLUMINA\tLB:lib1"

log_run "bwa_mem_align" "docker run --rm --cpus=16 --memory=32g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $BWA_IMAGE \
  bwa mem -t 16 -R '$RG' ref/GRCh38_no_alt.fasta \
    data/trimmed/HG002_chr20_R1.trimmed.fastq.gz \
    data/trimmed/HG002_chr20_R2.trimmed.fastq.gz \
  | docker run -i --rm --cpus=8 --memory=16g \
    --user $(id -u):$(id -g) \
    -v '$REPO_ROOT':/work -w /work \
    $SAMTOOLS_IMAGE \
    samtools sort -@ 8 -o results/align/HG002_chr20.sorted.bam -"

log_run "samtools_index_align" "docker run --rm --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $SAMTOOLS_IMAGE \
  samtools index results/align/HG002_chr20.sorted.bam"
