#!/usr/bin/env bash
# Copyright (c) 2024 Matthew Nelson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Sourced by external/task.sh for all 'sign:*' tasks

# Creates the detached signatures for binaries signed elsewhere (e.g. with Jsign and a YubiKey).
#
# Compares each signed file in dir [2] with its unsigned build output in build/out/$dirname_out/mingw/[1]/,
# writes codesign/$dirname_out/mingw/[1]/<file>.signature, and checks that the signature turns the unsigned
# file into the signed one, byte for byte. The signature's header records the unsigned file's hash, so
# packaging (and CI's mingw-signed job) refuses to apply it to anything but the same unsigned bytes.
function __sign:import:mingw {
  __util:require:var_set "$1" "[1] arch"
  __util:require:var_set "$2" "[2] signed files directory"
  __util:require:var_set "$dirname_out" "dirname_out"
  __util:require:var_set "$lib_names" "lib_names"
  __util:require:directory_exists "$2" "[2] signed files directory"

  local dir_signed=
  dir_signed="$(cd "$2" && pwd)"
  local dir_unsigned="$DIR_TASK/build/out/$dirname_out/mingw/$1"
  local dir_codesign="$DIR_TASK/codesign/$dirname_out/mingw/$1"

  local lib_name=
  for lib_name in $(echo "$lib_names" | tr "," " "); do
    __util:require:file_exists "$dir_unsigned/$lib_name" "Unsigned" "not found at $dir_unsigned/$lib_name (build it first: build:mingw:$1)"
    __util:require:file_exists "$dir_signed/$lib_name" "Signed" "not found at $dir_signed/$lib_name"
    if cmp -s "$dir_unsigned/$lib_name" "$dir_signed/$lib_name"; then
      __util:error "$dir_signed/$lib_name is identical to the unsigned build output (not signed?)"
    fi
  done

  DIR_TMP="$(mktemp -d)"
  trap 'rm -rf "$DIR_TMP"; unset DIR_TMP' SIGINT ERR

  mkdir -p "$dir_codesign"

  for lib_name in $(echo "$lib_names" | tr "," " "); do
    echo "
    Creating detached signature for build/out/$dirname_out/mingw/$1/$lib_name"

    rm -f "$dir_codesign/$lib_name.signature"
    ../tooling diff-cli create \
      --diff-ext-name ".signature" \
      "$dir_unsigned/$lib_name" \
      "$dir_signed/$lib_name" \
      "$dir_codesign"

    cp "$dir_unsigned/$lib_name" "$DIR_TMP/$lib_name"
    ../tooling diff-cli apply "$dir_codesign/$lib_name.signature" "$DIR_TMP/$lib_name"
    if ! cmp -s "$DIR_TMP/$lib_name" "$dir_signed/$lib_name"; then
      __util:error "codesign/$dirname_out/mingw/$1/$lib_name.signature does not reproduce $dir_signed/$lib_name"
    fi
    rm -f "$DIR_TMP/$lib_name"

    echo "
    unsigned $(sha256sum "$dir_unsigned/$lib_name" | cut -d ' ' -f 1)
    signed   $(sha256sum "$dir_signed/$lib_name" | cut -d ' ' -f 1)
    codesign/$dirname_out/mingw/$1/$lib_name.signature OK"
  done

  rm -rf "$DIR_TMP"
  unset DIR_TMP
  trap - SIGINT ERR
}

# Ensure source.util.sh has been sourced, and that
# DIR_TASK is set (i.e. this was sourced from task.sh)
__util:require:file_exists "$DIR_TASK/task.sh"
