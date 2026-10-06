#!/usr/bin/env bash
set -euo pipefail

# Build config.json from --<key> <value> flags, then run ./main with it.
#
# Every "--foo bar" pair is written into config.json as "foo": bar, with the
# value type auto-detected (true/false -> boolean, numeric -> number, else
# string). This mirrors the keys read by ./main, e.g.:
#
#   ./main_cli.sh \
#     --fodf /data/subject/neuro/csd/lmax8.nii.gz \
#     --mask_5tt /data/subject/neuro/mask_5tt/mask.nii.gz
#
# Pass --dry-run to only generate and print config.json without executing.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_OUT="config.json"
CONFIG_OUT_SET=0
OUTDIR=""
DRY_RUN=0
declare -a JSON_FRAGMENTS=()

usage() {
  cat <<'EOF'
Usage: ./main_cli.sh --<key> <value> [--<key> <value> ...] [--config PATH] [--dry-run]

Any --<key> <value> pair becomes a "<key>": <value> entry in config.json.

Required keys:
  --fodf      PATH    FODF volume (.nii.gz, SH order 8, descoteaux07 basis)
  --mask_5tt  PATH    5-tissue-type probability map (.nii.gz)

Optional keys:
  --seed_mask PATH    Seeding mask override; if omitted, WM (vol2 of 5TT) is used

Tracking parameters (all optional, defaults shown):
  --algo              prob|det             (default: prob)
  --seeding_type      npv|nt               (default: npv)
  --nbr_seeds         N                    (default: 10)
  --step              mm                   (default: 0.5)
  --theta             degrees              (default: 20)
  --sfthres           threshold            (default: 0.1)
  --sfthres_init      threshold            (default: 0.5)
  --min_length        mm                   (default: 20)
  --max_length        mm                   (default: 200)
  --particles         N                    (default: 15)
  --back_tracking     steps                (default: 2)
  --forward_tracking  steps                (default: 1)
  --compress          true|false           (default: true)
  --compress_value    mm                   (default: 0.2)
  --random_seed       N                    (default: 0)
  --sh_basis          descoteaux07|tournier (default: descoteaux07)

Options:
  --config PATH     write generated config to PATH instead of ./config.json
  --output_dir DIR  CLI-only: run ./main from inside DIR so tractogram/ lands there
  --dry-run         only generate and print config.json; do not run ./main
  -h, --help        show this help
EOF
}

to_json_fragment() {
  local key="$1" value="$2"
  if [[ -e "$value" ]]; then
    value="$(realpath "$value")"
  fi
  jq -n --arg k "$key" --arg v "$value" '
    if ($v == "true") then {($k): true}
    elif ($v == "false") then {($k): false}
    elif ($v | test("^-?[0-9]+$")) then {($k): ($v | tonumber)}
    elif ($v | test("^-?[0-9]*\\.[0-9]+$")) then {($k): ($v | tonumber)}
    else {($k): $v}
    end
  '
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --config)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --config" >&2; exit 1; }
      CONFIG_OUT="$2"
      CONFIG_OUT_SET=1
      shift 2
      ;;
    --output_dir)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --output_dir" >&2; exit 1; }
      OUTDIR="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --*=*)
      key="${1#--}"
      value="${key#*=}"
      key="${key%%=*}"
      JSON_FRAGMENTS+=("$(to_json_fragment "$key" "$value")")
      shift
      ;;
    --*)
      key="${1#--}"
      if [[ $# -ge 2 && "$2" != --* ]]; then
        value="$2"
        shift 2
      else
        value="true"
        shift
      fi
      JSON_FRAGMENTS+=("$(to_json_fragment "$key" "$value")")
      ;;
    *)
      echo "ERROR: unrecognized argument '$1'" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ${#JSON_FRAGMENTS[@]} -eq 0 ]]; then
  echo "ERROR: no --<key> <value> config options provided" >&2
  usage
  exit 1
fi

if [[ -n "${OUTDIR}" ]]; then
  mkdir -p "${OUTDIR}"
  OUTDIR="$(cd "${OUTDIR}" && pwd)"
  if [[ "${CONFIG_OUT_SET}" -eq 0 ]]; then
    CONFIG_OUT="${OUTDIR}/config.json"
  fi
fi

printf '%s\n' "${JSON_FRAGMENTS[@]}" | jq -s 'add' > "${CONFIG_OUT}"
CONFIG_OUT="$(realpath "${CONFIG_OUT}")"

echo "Wrote ${CONFIG_OUT}:"
cat "${CONFIG_OUT}"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo
  echo "Dry run: not executing ./main."
  exit 0
fi

if [[ -n "${OUTDIR}" ]]; then
  echo
  echo "Running ./main in ${OUTDIR} ..."
  ( cd "${OUTDIR}" && CONFIG="${CONFIG_OUT}" bash "${SCRIPT_DIR}/main" )
else
  echo
  echo "Running ./main with CONFIG=${CONFIG_OUT} ..."
  CONFIG="${CONFIG_OUT}" bash "${SCRIPT_DIR}/main"
fi
