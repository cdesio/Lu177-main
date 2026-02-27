#!/usr/bin/env bash
set -euo pipefail

# Quick end-to-end test for Lu177 pipeline:
# decaySimulation -> DNAsimulation (PS mode) -> Lu177 clustering

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DECAY_DIR="${ROOT_DIR}/decaySimulation"
DNA_SIM_DIR="${ROOT_DIR}/DNAsimulation/simulation"
DNA_GEO_DIR="${ROOT_DIR}/DNAsimulation/geometryFiles"
DNA_CLUSTER_DIR="${ROOT_DIR}/DNAsimulation/Clustering"

EVENTS="${EVENTS:-20}"
TAG="${TAG:-quick_test_$(date +%Y%m%d_%H%M%S)}"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/quick_test_runs/${TAG}}"

DECAY_BUILD="${DECAY_DIR}/build"
DNA_BUILD="${DNA_SIM_DIR}/build"
DNA_CLUSTER_BUILD="${DNA_CLUSTER_DIR}/build"

SUGAR_FILE="${DNA_GEO_DIR}/sugarPos_4x4_300nm.csv"
HISTONE_FILE="${DNA_GEO_DIR}/histonePositions_4x4_300nm.csv"

log() {
  echo "[quick_test] $*"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

build_if_needed() {
  local src_dir="$1"
  local build_dir="$2"
  local exe_name="$3"

  if [[ -x "${build_dir}/${exe_name}" ]]; then
    log "${exe_name} already built: ${build_dir}/${exe_name}"
    return
  fi

  log "Building ${exe_name} in ${build_dir}"
  mkdir -p "${build_dir}"
  cmake -S "${src_dir}" -B "${build_dir}"
  cmake --build "${build_dir}" -j
}

maybe_build_dna_clustering() {
  if ls "${DNA_CLUSTER_BUILD}"/clustering*.so >/dev/null 2>&1; then
    log "Lu177 clustering module already built."
    return
  fi
  log "Building Lu177 clustering module."
  mkdir -p "${DNA_CLUSTER_BUILD}"
  cmake -S "${DNA_CLUSTER_DIR}" -B "${DNA_CLUSTER_BUILD}"
  cmake --build "${DNA_CLUSTER_BUILD}" -j
}

need_cmd cmake
need_cmd python3

mkdir -p "${OUT_DIR}"
log "Output directory: ${OUT_DIR}"

build_if_needed "${DECAY_DIR}" "${DECAY_BUILD}" "decay"
build_if_needed "${DNA_SIM_DIR}" "${DNA_BUILD}" "dna"

if [[ ! -f "${SUGAR_FILE}" || ! -f "${HISTONE_FILE}" ]]; then
  log "Generating geometry CSV files."
  (
    cd "${DNA_GEO_DIR}"
    python3 plotChromatinFibreSection.py
  )
fi

if [[ ! -f "${SUGAR_FILE}" || ! -f "${HISTONE_FILE}" ]]; then
  echo "Geometry files were not generated as expected." >&2
  exit 1
fi

DECAY_MAC="${OUT_DIR}/Ra224_quick_test.in"
cat > "${DECAY_MAC}" <<EOF2
/control/verbose 1
/run/verbose 1
/det/cellPos_min 155 micrometer
/det/cellPos_max 165 micrometer
/run/initialize
/gun/particle ion
/gun/ion 88 224 0 0
/run/printProgress 100
/run/beamOn ${EVENTS}
EOF2

log "Running decay simulation (${EVENTS} primaries)."
(
  cd "${OUT_DIR}"
  "${DECAY_BUILD}/decay" -mac "${DECAY_MAC}" -out "decay_${TAG}" -seed 42
)

PS_FILE="${OUT_DIR}/decay_${TAG}.bin"
if [[ ! -s "${PS_FILE}" ]]; then
  echo "Phase-space file missing or empty: ${PS_FILE}" >&2
  echo "Try increasing EVENTS (e.g. EVENTS=200)." >&2
  exit 1
fi
log "Phase-space generated: ${PS_FILE}"

log "Running DNA simulation from phase-space."
(
  cd "${OUT_DIR}"
  "${DNA_BUILD}/dna" \
    -mac "${DNA_SIM_DIR}/dna_PS.in" \
    -out "dna_${TAG}" \
    -sugar "${SUGAR_FILE}" \
    -histone "${HISTONE_FILE}" \
    -PS "${PS_FILE}" \
    -seed 42
)

DNA_ROOT="${OUT_DIR}/dna_${TAG}.root"
if [[ ! -s "${DNA_ROOT}" ]]; then
  echo "DNA ROOT output missing: ${DNA_ROOT}" >&2
  exit 1
fi
log "DNA output: ${DNA_ROOT}"

log "Running Lu177 clustering."
maybe_build_dna_clustering
(
  cd "${DNA_CLUSTER_DIR}"
  python3 run.py \
    --filename "${DNA_ROOT}" \
    --output "${OUT_DIR}/damage_${TAG}.csv" \
    --sugar "${SUGAR_FILE}" \
    --copy 0
)
log "Lu177 clustering output: ${OUT_DIR}/damage_${TAG}.csv"
log "Lu177 clustering DSB output: ${OUT_DIR}/DSBclusterSize_damage_${TAG}.csv"

log "Quick test pipeline complete."
