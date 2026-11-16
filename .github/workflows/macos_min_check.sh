#!/usr/bin/env bash
# Checks macOS build output against the minimum OS floor.
#
# Usage: macos_min_check.sh <arch> <file>...   arch: aarch64 or x86_64
#
# aarch64 files must have exactly one minimum-version load command, LC_BUILD_VERSION with minos 11.0.
# x86_64 files must have exactly one, LC_VERSION_MIN_MACOSX with version 10.9. Any other result fails,
# including a raised or lowered minimum. Prints each file's minimum and SDK version.
# Uses $OTOOL if set (e.g. osxcross's <triple>-otool on Linux), else otool.
set -euo pipefail

readonly OTOOL="${OTOOL:-otool}"

if [ $# -lt 2 ]; then
  echo 1>&2 "Usage: $0 aarch64|x86_64 <file>..."
  exit 2
fi

case "$1" in
  aarch64) readonly EXPECTED="LC_BUILD_VERSION 11.0" ;;
  x86_64)  readonly EXPECTED="LC_VERSION_MIN_MACOSX 10.9" ;;
  *)
    echo 1>&2 "Unknown arch '$1'"
    exit 2
    ;;
esac
shift

fail=0

summary() {
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then echo "$1" >> "$GITHUB_STEP_SUMMARY"; fi
}

summary "| File | Minimum OS load command (expected ${EXPECTED}) | SDK |"
summary "| --- | --- | --- |"

for file in "$@"; do
  if [ ! -f "$file" ]; then
    echo "::error::$file does not exist"
    fail=1
    continue
  fi

  # One '<cmd> <minimum> <sdk>' line per minimum-version load command
  found="$("$OTOOL" -l "$file" | awk '
    $1 == "cmd" { cmd = $2; next }
    cmd == "LC_BUILD_VERSION" && $1 == "minos" { min = $2; next }
    cmd ~ /^LC_VERSION_MIN_/ && $1 == "version" { min = $2; next }
    (cmd == "LC_BUILD_VERSION" || cmd ~ /^LC_VERSION_MIN_/) && $1 == "sdk" { print cmd, min, $2; cmd = "" }
  ')"

  echo "$file: ${found:-no minimum-version load command}"
  summary "| \`$(basename "$file")\` | $(echo "${found:-none}" | cut -d ' ' -f 1-2 | tr '\n' ' ') | $(echo "${found:-none}" | cut -d ' ' -f 3 | tr '\n' ' ') |"

  if [ "$(echo "$found" | cut -d ' ' -f 1-2)" != "$EXPECTED" ]; then
    echo "::error::$file: expected exactly '$EXPECTED', found '$(echo "$found" | tr '\n' ';')'"
    fail=1
  fi
done

exit "$fail"
