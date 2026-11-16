#!/usr/bin/env bash
# Pulls and pushes build-env images according to build-env/digests. Used by build-env.yml.
#
# Usage:
#   build_env_images.sh require <name>...  Pulls each image by its pinned digest and tags it :latest. Fails if any isn't pinned.
#   build_env_images.sh pull <name>...     Same, but skips (with a message) images whose line is still a placeholder.
#   build_env_images.sh push <name>...     Pushes each image whose line is still a placeholder, and prints
#                                          '<name>=<digest>' lines on stdout. Pinned images are left alone.
#   build_env_images.sh pinned <name>      Exits 0 if the image is pinned, 1 if its line is a placeholder.
#
# <name> is the short name (e.g. linux-libc.aarch64), as in build-env/digests. Every name must have a line there.
# build-env/task.sh skips building an image whose local :latest is its pinned digest, so pulling the pinned images
# first makes it build only the placeholder ones. To rebuild an image, set its line back to a placeholder.
set -euo pipefail

DIR_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
readonly DIR_ROOT
readonly FILE_DIGESTS="$DIR_ROOT/build-env/digests"
readonly DOCKER="${DOCKER:-docker}"

ORG="$(sed -n 's/^readonly ORG="\(.*\)"$/\1/p' "$DIR_ROOT/build-env/task.sh")"
if [ -z "$ORG" ]; then
  echo 1>&2 "::error::ORG not found in build-env/task.sh"
  exit 1
fi
readonly ORG

function digest_of {
  local line=
  line="$(grep -E "^$(printf '%s' "$1" | sed 's/[.]/[.]/g')=" "$FILE_DIGESTS" || true)"
  if [ -z "$line" ]; then
    echo 1>&2 "::error::No line for '$1' in build-env/digests"
    exit 1
  fi
  echo "${line#*=}"
}

function is_pinned {
  digest_of "$1" | grep -qE '^sha256:[0-9a-f]{64}$'
}

function pull {
  local digest=
  digest="$(digest_of "$1")"
  "$DOCKER" pull "$ORG.$1@$digest"
  "$DOCKER" tag "$ORG.$1@$digest" "$ORG.$1:latest"
}

if [ $# -lt 2 ]; then
  echo 1>&2 "Usage: $0 require|pull|push|pinned <name>..."
  exit 2
fi
readonly CMD="$1"; shift

# Check every name has a line before doing anything
for name in "$@"; do digest_of "$name" > /dev/null; done

case "$CMD" in
  require)
    for name in "$@"; do
      if ! is_pinned "$name"; then
        echo 1>&2 "::error::$name must be pinned in build-env/digests before this job can run"
        exit 1
      fi
    done
    for name in "$@"; do pull "$name"; done
    ;;
  pull)
    for name in "$@"; do
      if is_pinned "$name"; then
        pull "$name"
      else
        echo 1>&2 "$name is not pinned yet, so build-env/task.sh will build it"
      fi
    done
    ;;
  push)
    for name in "$@"; do
      if is_pinned "$name"; then
        echo 1>&2 "$name is already pinned, not pushing"
        continue
      fi
      echo "$name=$("$DIR_ROOT/.github/workflows/push_image.sh" "$ORG.$name")"
    done
    ;;
  pinned)
    is_pinned "$1"
    ;;
  *)
    echo 1>&2 "Unknown command '$CMD'"
    exit 2
    ;;
esac
