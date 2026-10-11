#!/usr/bin/env bash
# Generates resume.pdf from index.html using headless Chrome (or Chromium).
# Usage: ./print-pdf.sh [output.pdf]
#
# The phone number is only included in the PDF, never in the published HTML.
# It's read from $RESUME_PHONE or from the first line of .phone (gitignored).
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
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
tmp="$tmp_dir/resume.pdf"

phone="${RESUME_PHONE:-}"
if [[ -z "$phone" && -f .phone ]]; then
  phone="$(head -1 .phone)"
fi
if [[ -z "$phone" ]]; then
  echo "Warning: no phone number found (set RESUME_PHONE or create .phone); omitting it" >&2
  phone_item=""
else
  phone_item="<li data-test-name=\"contact-phone\"><a href=\"tel:${phone//[^0-9+]/}\"><svg class=\"icon\" viewBox=\"0 0 24 24\"><path fill=\"currentColor\" d=\"M6.62,10.79C8.06,13.62 10.38,15.94 13.21,17.38L15.41,15.18C15.69,14.9 16.08,14.82 16.43,14.93C17.55,15.3 18.75,15.5 20,15.5A1,1 0 0,1 21,16.5V20A1,1 0 0,1 20,21A17,17 0 0,1 3,4A1,1 0 0,1 4,3H7.5A1,1 0 0,1 8.5,4C8.5,5.25 8.7,6.45 9.07,7.57C9.18,7.92 9.1,8.31 8.82,8.59L6.62,10.79Z\"/></svg><span>$phone</span></a></li>"
fi

# Print a copy of the page with the phone number added; <base> keeps the
# stylesheet and image paths pointing at this directory
page="$tmp_dir/index.html"
BASE="<base href=\"file://$PWD/\" />" PHONE_ITEM="$phone_item" awk '
  /<!-- phone: added by print-pdf.sh -->/ { print ENVIRON["PHONE_ITEM"]; next }
  { print }
  /<head>/ { print ENVIRON["BASE"] }
' index.html >"$page"
if [[ -n "$phone_item" ]] && ! grep -q 'contact-phone' "$page"; then
  echo "Could not find the phone placeholder in index.html" >&2
  exit 1
fi

# Chrome logs noise to stderr even on success, so only show it on failure
if ! errors="$("$chrome" \
  --headless \
  --disable-gpu \
  --no-pdf-header-footer \
  --print-to-pdf="$tmp" \
  "file://$page" 2>&1)" || [[ ! -s "$tmp" ]]; then
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
