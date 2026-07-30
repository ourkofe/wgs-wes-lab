#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

GATK_IMAGE="broadinstitute/gatk:4.6.2.0"
log_docker_digest "$GATK_IMAGE"

log_run "create_seq_dict" "docker run --rm --cpus=4 --memory=8g \
  --user $(id -u):$(id -g) \
  -v '$REPO_ROOT':/work -w /work \
  $GATK_IMAGE \
  gatk CreateSequenceDictionary -R ref/GRCh38_no_alt.fasta"
