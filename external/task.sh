#!/usr/bin/env bash
# Copyright (c) 2023 Matthew Nelson
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
export LC_ALL=C
set -e

readonly CMD_TASK="$1"
readonly DIR_TASK="$( cd "$( dirname "$0" )" >/dev/null && pwd )"
if [ -n "$CMD_TASK" ]; then shift; fi

# The tor release external/tor must be at. Checked after every `git submodule update`, which
# resets the submodule to the commit in the index: a tor bump that isn't staged (or committed)
# fails here, instead of silently building the old tor. Update together with the submodule.
readonly TOR_TAG="tor-0.4.9.16"
readonly TOR_COMMIT="c51547ca15ea665950dd154e160051c57f5719db"

function build:all { ## Builds all targets
  build:all:linux-libc
  build:all:macos
  build:all:mingw
}

function build:all:linux-libc { ## Builds all Linux Libc targets
  build:linux-libc:aarch64
  build:linux-libc:x86_64
}

function build:all:macos { ## Builds all macOS LTS targets
  build:macos-lts:aarch64
  build:macos-lts:x86_64
}

function build:all:mingw { ## Builds all MinGW targets
  build:mingw:x86_64
}

function build:linux-libc:aarch64 { ## Builds Linux Libc aarch64
  local os_name="linux"
  local os_subtype="-libc"
  local os_arch="aarch64"
  local openssl_target="linux-aarch64"
  __build:configure:target:init
  __build:docker:execute
}

function build:linux-libc:x86_64 { ## Builds Linux Libc x86_64
  local os_name="linux"
  local os_subtype="-libc"
  local os_arch="x86_64"
  local openssl_target="linux-x86_64"
  __build:configure:target:init
  __build:docker:execute
}

function build:macos-lts:aarch64 { ## Builds macOS LTS (SDK 12.3) aarch64
  local os_name="macos"
  local os_subtype="-lts"
  local os_arch="aarch64"
  local openssl_target="darwin64-arm64-cc"
  local cc_clang="yes"
  __build:configure:target:init
  __build:docker:execute
}

function build:macos-lts:x86_64 { ## Builds macOS LTS (SDK 12.3) x86_64
  local os_name="macos"
  local os_subtype="-lts"
  local os_arch="x86_64"
  local openssl_target="darwin64-x86_64-cc"
  local cc_clang="yes"
  __build:configure:target:init
  __build:docker:execute
}

function build:mingw:x86_64 { ## Builds MinGW x86_64
  local os_name="mingw"
  local os_arch="x86_64"
  local openssl_target="mingw64"
  __build:configure:target:init
  __build:docker:execute
}

function clean { ## Deletes the external/build directory
  rm -rf "$DIR_TASK/build"
}

function help { ## THIS MENU
  echo "
    $0
    Copyright (C) 2023 Matthew Nelson

    Tasks for compiling, codesigning, and packaging tor

    Location: $DIR_TASK
    Syntax: $0 [task] [option] [args]

    Tasks:
$(
    # function names + comments & colorization
    grep -E '^function .* {.*?## .*$$' "$0" |
    grep -v "^function __" |
    sed -e 's/function //' |
    sort |
    awk 'BEGIN {FS = "{.*?## "}; {printf "        \033[93m%-30s\033[92m %s\033[0m\n", $1, $2}'
)

    Options:
        --dry-run                      Debugging output that does not execute.
        --rebuild                      Causes a complete rebuild of the target(s).

    Example: $0 build:all --dry-run
  "
}

function package:all { ## Packages all build/out contents & geoip files
  package:geoip
  package:linux-libc
  package:macos
  package:mingw
}

function package:geoip { ## Packages geoip & geoip6 files
  local dirname_final="resource-geoip"
  __package:geoip "geoip"
  __package:geoip "geoip6"
}

function package:linux-libc { ## Packages all Linux Libc build/out contents
  local archs="aarch64 x86_64"
  local os_subtype="-libc"
  __package:linux:jvm
  unset archs os_subtype

  local dirname_out="tor-gpl"
  local dirname_final="resource-lib-tor-gpl"
  local target="linux-libc"

  local native_resource="io.matthewnelson.kmp.tor.resource.lib.tor.internal"
  __package:native "aarch64" "libtor.so" "linuxArm64Main"
  __package:native "x86_64" "libtor.so" "linuxX64Main"

  dirname_final="resource-exec-tor-gpl"
  native_resource="io.matthewnelson.kmp.tor.resource.exec.tor.internal"
  __package:native "aarch64" "tor" "linuxArm64Main"
  __package:native "x86_64" "tor" "linuxX64Main"
}

function package:macos { ## Packages all macOS LTS build/out contents
  local dirname_out="tor-gpl"
  local dirname_final="resource-lib-tor-gpl"
  local rpath_native="resource/lib/tor"
  local target="macos-lts"
  __package:jvm:codesign "aarch64" "libtor.dylib"
  __package:jvm:codesign "x86_64" "libtor.dylib"
  __package:jvm:move:macos-lts

  dirname_final="resource-exec-tor-gpl"
  rpath_native="resource/exec/tor"
  __package:jvm:codesign "aarch64" "tor"
  __package:jvm:codesign "x86_64" "tor"
  __package:jvm:move:macos-lts
}

function package:mingw { ## Packages all MinGW build/out contents
  local dirname_out="tor-gpl"
  local dirname_final="resource-lib-tor-gpl"
  local rpath_native="resource/lib/tor"
  local target="mingw"
  __package:jvm:codesign "x86_64" "tor.dll"

  dirname_final="resource-exec-tor-gpl"
  rpath_native="resource/exec/tor"
  __package:jvm:codesign "x86_64" "tor.exe"

  unset rpath_native

  dirname_final="resource-lib-tor-gpl"
  local native_resource="io.matthewnelson.kmp.tor.resource.lib.tor.internal"
  __package:native:codesign "x86_64" "tor.dll" "mingwX64Main"

  dirname_final="resource-exec-tor-gpl"
  native_resource="io.matthewnelson.kmp.tor.resource.exec.tor.internal"
  __package:native:codesign "x86_64" "tor.exe" "mingwX64Main"

  unset native_resource
  unset dirname_out

  local permissions="664"
  local gzip="no"
  echo "# https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-redirection#how-to-redirect-dlls-for-unpackaged-apps" > "$DIR_TASK/build/tor.exe.local"

  dirname_final="resource-exec-tor-gpl"
  __package:file "build" "jvmMain/resources/io/matthewnelson/kmp/tor/resource/exec/tor/native/mingw" "tor.exe.local"

  local native_resource="io.matthewnelson.kmp.tor.resource.exec.tor.internal"
  __package:file "build" "mingwX64Main" "tor.exe.local"

  rm -rf "$DIR_TASK/build/tor.exe.local"
}

function sign:mingw:import { ## 1 ARG - [1]: dir with the signed tor.exe and tor.dll (see docs/UPDATING.md)
  if [ $# -ne 1 ]; then
    __util:error "Usage: $0 $CMD_TASK </path/to/dir/with/signed/tor.exe/and/tor.dll>"
  fi

  local lib_names="tor.dll,tor.exe"
  local dirname_out="tor-gpl"

  __sign:import:mingw "x86_64" "$1"
}

function validate { ## Checks the build/package directory output against expected sha256 hashes
  local targets="JVM"
  targets+=",LINUX_ARM64,LINUX_X64"
  targets+=",MACOS_ARM64,MACOS_X64"
  targets+=",MINGW_X64"

  cd "$DIR_TASK/.."
  ./gradlew clean -PKMP_TARGETS="$targets"
  ./gradlew prepareKotlinBuildScriptModel -PKMP_TARGETS="$targets"

  __validate:report "resource-exec-tor-gpl"
  __validate:report "resource-geoip"
  __validate:report "resource-lib-tor-gpl"
}

function validate:update_hashes { ## Updates gradle extensions with new hash values
  local extension_kt_files="ExecTorResourceValidationExtension.kt"
  extension_kt_files+=",LibTorResourceValidationExtension.kt"
  extension_kt_files+=",GeoipResourceValidationExtension.kt"

  local output=""
  output="$(validate | grep "ERROR\[" | grep "did not match")"
  local extension_kt_file=""
  local new_hash=""
  local old_hash=""
  local print_next_line=""
  local err_line=""
  local file=""
  local update=""

  for err_line in echo $output; do
    if [ -n "$print_next_line" ]; then
      echo "$print_next_line $err_line"
      print_next_line=""
    fi

    if echo "$err_line" | grep -q "hash\["; then
      new_hash="$(echo "$err_line" | cut -d '[' -f 2 | cut -d ']' -f 1)"
      old_hash=""
      continue
    fi

    if echo "$err_line" | grep -q "expected\["; then
      old_hash="$(echo "$err_line" | cut -d '[' -f 2 | cut -d ']' -f 1)"
      if [ ${#old_hash} -ne 64 ]; then
        # Next line will be the fs path
        print_next_line="Unable to update hash value to $new_hash for"
        old_hash=""
        new_hash=""
        continue
      fi

      for extension_kt_file in $(echo "$extension_kt_files" | tr "," " "); do
        file="$DIR_TASK/../build-logic/src/main/kotlin/resource/validation/extensions/$extension_kt_file"
        __util:require:file_exists "$file"
        update=$(sed "s+$old_hash+$new_hash+g" "$file")
        echo "$update" > "$file"
      done

      old_hash=""
      new_hash=""
    fi
  done

  validate
}

function __require:tor:commit {
  local commit=
  commit="$(${GIT} -C "$DIR_TASK/tor" rev-parse HEAD)"
  if [ "$commit" = "$TOR_COMMIT" ]; then return 0; fi

  __util:error "external/tor is at $commit, expected $TOR_TAG ($TOR_COMMIT)

    git submodule update checks out the commit recorded in the index. If you moved
    external/tor, stage it first (git add external/tor). If you meant to bump tor,
    update TOR_TAG and TOR_COMMIT in $DIR_TASK/task.sh"
}

# Run
if [ -z "$CMD_TASK" ] || [ "$CMD_TASK" = "help" ] || echo "$CMD_TASK" | grep -q "^__"; then
  help
elif ! grep -qE "^function $CMD_TASK {" "$0"; then
  help
  . "$DIR_TASK/source.task/source.util.sh"
  __util:error "Unknown task '$CMD_TASK'"
else
  . "$DIR_TASK/source.task/source.util.sh"
  . "$DIR_TASK/source.task/source.options.sh" "$@"
  __util:require:no_build_lock

  # Ensure always starting in the external directory
  cd "$DIR_TASK"
  mkdir -p "build"

  if echo "$CMD_TASK" | grep -q "^build"; then
    . "$DIR_TASK/source.task/source.build.sh"
    __util:require:cmd "$GIT" "git"

    ${GIT} submodule update --init
    __require:tor:commit

    __util:require:no_build_lock
    trap '__build:cleanup' EXIT
    echo "$CMD_TASK" > "$FILE_BUILD_LOCK"

    __util:git:clean "libevent"
    __util:git:apply_patches "libevent"
    __util:git:clean "openssl"
    __util:git:apply_patches "openssl"
    __util:git:clean "tor"
    __util:git:apply_patches "tor"
    __util:git:clean "xz"
    __util:git:apply_patches "xz"
    __util:git:clean "zlib"
    __util:git:apply_patches "zlib"
  elif echo "$CMD_TASK" | grep -q "^package"; then
    . "$DIR_TASK/source.task/source.package.sh"
    __util:require:cmd "$GIT" "git"

    ${GIT} submodule update --init "$DIR_TASK/tor"
    __require:tor:commit
    __util:git:clean "tor"

    __util:require:no_build_lock
    trap 'rm -rf "$FILE_BUILD_LOCK"; rm -rf "$DIR_STAGING"' EXIT
    echo "$CMD_TASK" > "$FILE_BUILD_LOCK"
    DIR_STAGING="$(mktemp -d)"
  elif echo "$CMD_TASK" | grep -q "^sign"; then
    . "$DIR_TASK/source.task/source.sign.sh"
    trap 'rm -rf "$FILE_BUILD_LOCK"' EXIT
    echo "$CMD_TASK" > "$FILE_BUILD_LOCK"
  elif echo "$CMD_TASK" | grep -q "^validate"; then
    . "$DIR_TASK/source.task/source.validate.sh"
  fi

  TIMEFORMAT="
    Task '$CMD_TASK' completed in %3lR
  "
  if [ "$CMD_TASK" = "sign:mingw:import" ]; then
    time "$CMD_TASK" "$@"
  else
    time "$CMD_TASK"
  fi
fi
