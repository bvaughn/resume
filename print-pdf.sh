#!/usr/bin/env bash
# Generates resume.pdf from index.html using headless Chrome (or Chromium).
# Usage: ./print-pdf.sh [output.pdf]
set -euo pipefail

# Resolve the output path before changing directories
output="${1:-resume.pdf}"
if [[ "$output" != /* ]]; then
  output="$PWD/$output"
fi

cd "$(dirname "$0")"

find_chrome() {
  if [[ -n "${CHROME:-}" ]]; then
    if [[ ! -x "$CHROME" ]] && ! command -v "$CHROME" >/dev/null 2>&1; then
      echo "CHROME is set to \"$CHROME\" but that is not an executable" >&2
      exit 1
    fi
    echo "$CHROME"
    return
  fi

  local candidates=(
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    "/Applications/Chromium.app/Contents/MacOS/Chromium"
    google-chrome
    google-chrome-stable
    chromium
    chromium-browser
  )
  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]] || command -v "$candidate" >/dev/null 2>&1; then
      echo "$candidate"
      return
    fi
  done

  echo "Chrome not found; set the CHROME environment variable to its path" >&2
  exit 1
}

chrome="$(find_chrome)"

# Write to a temp file so a failed run leaves any existing PDF untouched
tmp="$(mktemp -d)/resume.pdf"
trap 'rm -rf "$(dirname "$tmp")"' EXIT

# Chrome logs noise to stderr even on success, so only show it on failure
if ! errors="$("$chrome" \
  --headless \
  --disable-gpu \
  --no-pdf-header-footer \
  --print-to-pdf="$tmp" \
  "file://$PWD/index.html" 2>&1)" || [[ ! -s "$tmp" ]]; then
  echo "$errors" >&2
  echo "Failed to generate $output" >&2
  exit 1
fi

# The print stylesheet is designed to fit on a single page
pages="$(grep -a -o '/Count [0-9]*' "$tmp" | head -1 | awk '{print $2}')"
if [[ "$pages" != "1" ]]; then
  echo "Warning: $output has ${pages:-an unknown number of} pages (expected 1)" >&2
fi

mv "$tmp" "$output"
echo "Wrote $output"
