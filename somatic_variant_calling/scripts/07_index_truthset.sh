#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib_log.sh"

GATK_IMAGE="broadinstitute/gatk:4.6.2.0"
log_docker_digest "$GATK_IMAGE"

for f in high-confidence_sSNV_in_HC_regions_v1.2.1.vcf.gz high-confidence_sINDEL_in_HC_regions_v1.2.1.vcf.gz; do
  log_run "index_${f}" "docker run --rm --log-driver=none --user $(id -u):$(id -g) \
    -v '$REPO_ROOT':/work -w /work \
    $GATK_IMAGE \
    gatk IndexFeatureFile -I ref/truth/${f}"
done
