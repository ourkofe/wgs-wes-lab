#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

SAMTOOLS_IMAGE="staphb/samtools:latest"
REMOTE_BAM="https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/HG002_NA24385_son/NIST_HiSeq_HG002_Homogeneity-10953946/NHGRI_Illumina300X_AJtrio_novoalign_bams/HG002.GRCh38.300x.bam"

mkdir -p "$REPO_ROOT/data"
log_docker_digest "$SAMTOOLS_IMAGE"

# 원격 BAM에서 chr20 부분만 추출 (전체 다운로드 없이)
log_run "extract_chr20_bam" "docker run --rm --cpus=8 --memory=16g \
  --user $(id -u):$(id -g) \
  -v /etc/ssl/certs:/etc/ssl/certs:ro \
  -v '$REPO_ROOT':/work -w /work \
  $SAMTOOLS_IMAGE \
  samtools view -b '$REMOTE_BAM' chr20 -o /work/data/HG002_chr20.bam"

# 재정렬 연습을 위해 BAM -> fastq로 변환 (paired-end)
log_run "bam_to_fastq" "docker run --rm --cpus=8 --memory=16g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $SAMTOOLS_IMAGE \
  sh -c 'samtools sort -n -@ 8 -o /work/data/HG002_chr20.namesorted.bam /work/data/HG002_chr20.bam && \
  samtools fastq -@ 8 \
    -1 /work/data/HG002_chr20_R1.fastq.gz \
    -2 /work/data/HG002_chr20_R2.fastq.gz \
    -0 /dev/null -s /dev/null -n \
    /work/data/HG002_chr20.namesorted.bam'"

du -sh "$REPO_ROOT/data"
