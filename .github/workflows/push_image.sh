#!/usr/bin/env bash
# Pushes <image>:latest and prints its registry manifest digest (sha256:<64 hex>) on stdout.
#
# Usage: push_image.sh <image>   e.g. push_image.sh ghcr.io/sparrowwallet/build-env.base
#
# The digest comes from the `digest: sha256:...` line of `docker push`'s own output. Only if that
# line is missing does it fall back to the image's RepoDigests. Fails if neither gives a digest.
# `docker push` output goes to stderr, so it shows in the log without mixing into stdout.
set -euo pipefail

readonly DOCKER="${DOCKER:-docker}"

if [ $# -ne 1 ] || [ -z "$1" ]; then
  echo 1>&2 "Usage: $0 <image>"
  exit 2
fi
readonly IMAGE="$1"

push_output="$("$DOCKER" push "$IMAGE:latest" 2>&1 | tee /dev/stderr)"

digest="$(echo "$push_output" | sed -n 's/.*digest: \(sha256:[0-9a-f]\{64\}\).*/\1/p' | tail -n 1)"

if [ -z "$digest" ]; then
  echo 1>&2 "No 'digest: sha256:...' line in docker push output for $IMAGE:latest, falling back to RepoDigests"
  digest="$("$DOCKER" image inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' "$IMAGE:latest" \
    | awk -v prefix="$IMAGE@" 'index($0, prefix) == 1 { print substr($0, length(prefix) + 1); exit }')"
fi

if ! echo "$digest" | grep -qE '^sha256:[0-9a-f]{64}$'; then
  echo 1>&2 "::error::No registry digest for $IMAGE:latest, from either docker push output or RepoDigests (got '$digest')"
  exit 1
fi

echo "$digest"
