#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

BWA_IMAGE="staphb/bwa:latest"
SAMTOOLS_IMAGE="staphb/samtools:latest"
mkdir -p "$REPO_ROOT/results/align"
log_docker_digest "$BWA_IMAGE"

RUNS="ERR2000715 ERR2000716 ERR2000718 ERR2000720 ERR2000722"

for run in $RUNS; do
  # BWA aln: 고대 DNA 표준 파라미터 (-l 1024: seeding 사실상 비활성화, -n 0.01: 관대한 미스매치)
  log_run "bwa_aln_${run}" "docker run --rm --cpus=16 --memory=16g \
    --user $(id -u):$(id -g) \
    -v '$REPO_ROOT':/work -w /work \
    $BWA_IMAGE \
    bwa aln -l 1024 -n 0.01 -t 16 ref/GRCh38_no_alt.fasta data/${run}.fastq.gz \
    > results/align/${run}.sai"

  log_run "bwa_samse_${run}" "docker run --rm --cpus=8 --memory=16g \
    --user $(id -u):$(id -g) \
    -v '$REPO_ROOT':/work -w /work \
    $BWA_IMAGE \
    bwa samse -r '@RG\tID:${run}\tSM:Vindija33.19\tPL:ILLUMINA\tLB:lib1' \
      ref/GRCh38_no_alt.fasta results/align/${run}.sai data/${run}.fastq.gz \
    | docker run -i --rm --cpus=8 --memory=16g \
      --user $(id -u):$(id -g) \
      -v '$REPO_ROOT':/work -w /work \
      $SAMTOOLS_IMAGE \
      samtools sort -@ 8 -o results/align/${run}.sorted.bam -"

  log_run "index_${run}" "docker run --rm --user $(id -u):$(id -g) \
    -v '$REPO_ROOT':/work -w /work \
    $SAMTOOLS_IMAGE \
    samtools index results/align/${run}.sorted.bam"
done
