# COMPILATION DETAILS

`tor` is compiled by the `external/task.sh` script inside Docker containers, so that the output is reproducible.

Detached code signatures for the macOS and Windows builds are checked into `git` under `external/codesign/`, so
that anyone can verify that the signed binaries are the reproducible build plus the signature.

You can view the `help` output of `task.sh` by running it from the project's root directory.

```
$ git clone https://github.com/sparrowwallet/kmp-tor-resource.git
$ cd kmp-tor-resource
$ ./external/task.sh
```

### Toolchains

The containers are built from the Dockerfiles in [build-env](../build-env) (copied from
[05nelsonm/build-env](https://github.com/05nelsonm/build-env); the changes are listed in
[build-env/UPSTREAM.md](../build-env/UPSTREAM.md)) by the `build-env` workflow, pushed to
`ghcr.io/sparrowwallet/build-env.*` and pinned by digest in [build-env/digests](../build-env/digests). Every
`docker run` uses the pinned digest.

| Target              | Toolchain                                   | Minimum OS           |
|---------------------|---------------------------------------------|----------------------|
| `linux-libc` aarch64, x86_64 | crosstool-ng, gcc 8.5.0, glibc 2.23 sysroot | glibc 2.23 |
| `macos-lts` aarch64, x86_64  | osxcross, macOS SDK 12.3                    | macOS 11 (aarch64), 10.9 (x86_64) |
| `mingw` x86_64      | mingw-w64 (Debian 12)                       |                      |

The macOS images contain the macOS SDK, which isn't redistributed, so they (and the SDK mirror) are private. The Linux and MinGW images are public.

### Building

`./external/task.sh build:all` (or `build:<target>:<arch>`) compiles zlib, xz, openssl and libevent as static
libraries, then `tor` (with `--enable-gpl`) as a shared library (`libtor.so`, `libtor.dylib`, `tor.dll`) plus a
small launcher (`tor`, `tor.exe`) that loads it. The output goes to `external/build/out/tor-gpl/<target>/<arch>/`.

The submodules in `external/` must be at the commits listed in `SUBMODULES_EXPECTED` in `external/task.sh`; a
build stops if one isn't (for example, a submodule bump that wasn't staged).

CI builds every target on each push and checks the output: the glibc version required on Linux, the minimum
macOS version, and `tor --version` on Ubuntu 20.04 (x86_64 and aarch64), macOS (Apple Silicon and Intel) and
Windows.

### Signing

- **macOS:** the CI workflow, run by hand with `sign_macos`, signs `tor` and `libtor.dylib` with Sparrow's
  Developer ID (hardened runtime), notarizes them, and produces the detached signatures with
  [diff-cli][path-diff-cli].
- **Windows:** `tor.exe` and `tor.dll` are signed locally with Jsign; `./external/task.sh sign:mingw:import`
  produces the detached signatures.

See [UPDATING.md](UPDATING.md) for the steps.

### Packaging

The compiled output is "packaged" into the library modules' JVM resource directories (e.g.
`external/build/package/resource-lib-tor-gpl/src/jvmMain/resources`).

Running `./external/task.sh package:all` after a `build` task does the following:

- Applies the detached code signatures (macOS, Windows) via [diff-cli][path-diff-cli]. A signature only applies to
  the exact unsigned file it was made for.
- Gzips all compilations (and `tor`'s `geoip` and `geoip6` files), inside the pinned base container.
- Moves them to `external/build/package/resource-{name}/src/jvmMain/resources`.

### Validation

Every packaged file has an expected sha256 in `build-logic/src/main/kotlin/resource/validation/extensions`.
`./external/task.sh validate` reports any mismatch. A module whose packaged resources don't match falls back to
the mock resources in `mock-resources/`, so publishing is blocked unless every report is empty, and CI's `package`
job fails on any mismatch. See [DETERMINISTIC_BUILDS.md](DETERMINISTIC_BUILDS.md).

[path-diff-cli]: ../tools/diff-cli/README.md
