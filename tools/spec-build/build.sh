#!/usr/bin/env bash
# Rebuild a specification's web page (tools/spec-build/out/) and its PDF (next to the Markdown file).
# Usage: ./tools/spec-build/build.sh [toolchain|round1 ...]      (default: toolchain)
# Requires: pandoc, python3, node. First run installs playwright-core; if Chromium is missing, run:
#   npx playwright-core install chromium
set -euo pipefail
cd "$(dirname "$0")"
[ -d node_modules/playwright-core ] || npm install --silent
if [ $# -eq 0 ]; then set -- toolchain; fi
for doc in "$@"; do
  python3 build_web.py "$doc"
  python3 make_print.py "$doc"
  node make_pdf.js "$doc"
done
