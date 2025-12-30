#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGED_DIR="${ROOT_DIR}/packaged_skills"

if ! git -C "$ROOT_DIR" rev-parse --is-inside-work-tree &> /dev/null; then
    echo "[ERROR] Not inside a git repository."
    exit 1
fi

if ! command -v zip &> /dev/null; then
    echo "[ERROR] zip is required to package skills."
    exit 1
fi

shopt -s nullglob

zipclean() {
    zip -r "$1" "${@:2}" -x "*.DS_Store" "__MACOSX/*"
}

skill_manifests=("$ROOT_DIR"/*/SKILL.md)
if [[ ${#skill_manifests[@]} -eq 0 ]]; then
    exit 0
fi

mkdir -p "$PACKAGED_DIR"

packaged_files=()

for manifest in "${skill_manifests[@]}"; do
    skill_dir="$(dirname "$manifest")"
    skill_name="$(basename "$skill_dir")"

    if git -C "$ROOT_DIR" check-ignore -q "$skill_name"; then
        continue
    fi

    output="${PACKAGED_DIR}/${skill_name}.skill"
    temp_dir="$(mktemp -d)"
    temp_output="${temp_dir}/${skill_name}.skill"

    (cd "$ROOT_DIR" && zipclean "$temp_output" "$skill_name")

    if [[ -f "$output" ]] && cmp -s "$temp_output" "$output"; then
        rm -rf "$temp_dir"
        continue
    fi

    mv "$temp_output" "$output"
    rm -rf "$temp_dir"
    packaged_files+=("$output")
done

if [[ ${#packaged_files[@]} -gt 0 ]]; then
    git -C "$ROOT_DIR" add "${packaged_files[@]}"
fi
