#!/usr/bin/env bash
# Checks Linux libc build output against the glibc floor.
#
# Usage: glibc_check.sh <max glibc version> <file>...
#
# Fails if any file requires a GLIBC_ symbol version above <max glibc version>, or has a NEEDED
# library other than libtor.so, libc, libm, libdl, libpthread or ld-linux. Prints the newest
# GLIBC_ version each file requires, so drift shows up even while it stays under the maximum.
set -euo pipefail

if [ $# -lt 2 ]; then
  echo 1>&2 "Usage: $0 <max glibc version> <file>..."
  exit 2
fi

readonly MAX="$1"; shift
fail=0

summary() {
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then echo "$1" >> "$GITHUB_STEP_SUMMARY"; fi
}

summary "| File | Newest GLIBC_ required (max $MAX) | NEEDED |"
summary "| --- | --- | --- |"

for file in "$@"; do
  if [ ! -f "$file" ]; then
    echo "::error::$file does not exist"
    fail=1
    continue
  fi

  versions="$(readelf -V --wide "$file" | grep -o 'GLIBC_[0-9][0-9.]*' | sed 's/^GLIBC_//' | sort -u -V || true)"
  newest="$(echo "$versions" | tail -n 1)"
  needed="$(readelf -d --wide "$file" | sed -n 's/.*(NEEDED).*\[\(.*\)\]$/\1/p')"
  needed_line="$(echo "$needed" | tr '\n' ' ' | sed 's/ $//')"

  echo "$file: newest GLIBC_ required: ${newest:-none}"
  echo "$file: NEEDED: $needed_line"
  summary "| \`$(basename "$file")\` | ${newest:-none} | $needed_line |"

  for version in $versions; do
    if [ "$(printf '%s\n%s\n' "$version" "$MAX" | sort -V | tail -n 1)" != "$MAX" ]; then
      echo "::error::$file requires GLIBC_$version, above the maximum GLIBC_$MAX"
      fail=1
    fi
  done

  for lib in $needed; do
    case "$lib" in
      libtor.so|libc.so.*|libm.so.*|libdl.so.*|libpthread.so.*|ld-linux*) ;;
      *)
        echo "::error::$file has unexpected NEEDED library $lib"
        fail=1
        ;;
    esac
  done
done

exit "$fail"
