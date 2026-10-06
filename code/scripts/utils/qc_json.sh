#!/usr/bin/env bash
# Shared helpers for building the per-subject QC JSON incrementally.

qc_timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

# qc_init <path> — start a fresh QC json (top-level orchestrator only).
qc_init() {
    echo "{" > "$1"
}

# qc_write <path> <fragment> — append one stage's JSON fragment.
# <fragment> must be a bare '"key": { ... }' object, without a trailing
# comma — qc_write adds it. The last one written gets its comma stripped
# by qc_finalize.
qc_write() {
    local path="$1" fragment="$2"
    printf "%s,\n" "$fragment" >> "$path"
}

# qc_finalize <path> — strip the last stage's trailing comma, close the
# object, and pretty-print via jq if available.
qc_finalize() {
    local path="$1"
    [[ -f "$path" ]] || return 0
    sed -i '$ s/,$//' "$path"
    echo "}" >> "$path"
    if command -v jq >/dev/null 2>&1; then
        jq '.' "$path" > "${path}.tmp" 2>/dev/null && mv "${path}.tmp" "$path"
    fi
}
