#!/usr/bin/env bash
# Extract a section from CHANGELOG.md into Fastlane release_notes.txt
# Usage: extract_changelog.sh [section_heading] [changelog_path] [out_path]
# Default section: Unreleased
set -euo pipefail

SECTION="${1:-Unreleased}"
CHANGELOG="${2:-CHANGELOG.md}"
OUT="${3:-ios/fastlane/metadata/en-US/release_notes.txt}"

if [[ ! -f "$CHANGELOG" ]]; then
  echo "CHANGELOG not found: $CHANGELOG" >&2
  exit 1
fi

NOTES=$(awk -v section="$SECTION" '
  BEGIN { heading = "## " section; capturing = 0; started = 0 }
  $0 == heading { capturing = 1; next }
  /^## / {
    if (capturing) exit
  }
  capturing {
    if (!started && $0 ~ /^[[:space:]]*$/) next
    started = 1
    print
  }
' "$CHANGELOG")

# Trim trailing blank lines
NOTES=$(printf '%s\n' "$NOTES" | sed -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}')

if [[ -z "${NOTES//[[:space:]]/}" ]]; then
  echo "No notes found under '## $SECTION' in $CHANGELOG" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
printf '%s\n' "$NOTES" > "$OUT"
echo "Wrote release notes from '## $SECTION' to $OUT:"
echo "-----"
cat "$OUT"
echo "-----"
